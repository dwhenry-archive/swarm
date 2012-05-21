require 'ruby-debug'

module Swarm
  class Queen
    include Singleton
    include OutputHelper

    attr_reader :formatter

    SCHEMA_SANITIZATION_SED = "sed -e 's/ AUTO_INCREMENT=[0-9]*//' -e 's/--.*//'"
    MD5_CMD = RUBY_PLATFORM =~ /darwin/ ? 'md5' : 'md5sum'

    def self.rule
      instance.rule
    end

    def initialize
      load_environment
      @base_environment_name = Rails.env
      @base_environment_configuration = ActiveRecord::Base.configurations[@base_environment_name].dup
      @base_environment_db = @base_environment_configuration['database']
      @project_root = Rails.root
      @runtimes = []
      choose_formatter
    end

    def rule
      set_number_of_drones
      update_schema
      dump_schema
      build_drone_deployment_config
      populate_queue

      @formatter.started
      voice.start # not sure I like calling this a 'voice'
      start_server { deploy_drones }
      at_exit { @server.close if @server }
      Process.waitall
      @formatter.completed
      save_runtimes(@formatter.runtimes)
      voice.stop
      describe_processed_files if Swarm.debug? || @formatter.any_failed?
      exit 1 if @formatter.any_failed? || @formatter.any_undefined?
    end

    protected

    def order_by_runtime(files)
      if File.exists?(runtimes_filename)
        files_with_runtime = File.read(runtimes_filename).split("\n")
        (files - files_with_runtime) + (files_with_runtime & files)
      else
        files
      end
    end

    def save_runtimes(runtimes)
      runtimes = runtimes.sort_by { |runtime, file| runtime }.reverse
      FileUtils.mkdir_p(Swarm.runtimes_dir)
      File.open(runtimes_filename, "w") do |fd|
        fd.puts(runtimes.map { |runtime, file| file }.join("\n"))
      end
    end

    def runtimes_filename
      File.join(Swarm.runtimes_dir, Drone.pilot.class.name.demodulize)
    end

    def set_number_of_drones
      @num_drones = if Swarm.num_drones
        Swarm.num_drones.to_i
      else
        cores = detect_cores
        (cores * 2 - (cores / 2))
      end
      drone_str = @num_drones == 1 ? "drone" : "drones"
      debug("Starting #{@num_drones} #{drone_str}")
    end

    def build_drone_deployment_config
      default_options = {:create_database => false, :reload_schema => false, :db_access_opts => db_access_opts, :project_root => @project_root}
      @drone_config = {@base_environment_db => default_options}
      (@num_drones - 1).times { |i| @drone_config["#{@base_environment_db}#{i + 1}"] = default_options }

      detect_databases_needing_create.each { |db| @drone_config[db][:create_database] = true }
      detect_databases_needing_schema_reload.each {|db| @drone_config[db][:reload_schema] = true }

      debug(@drone_config.inspect)
    end

    def detect_databases_needing_create
      existing_dbs = `echo "show databases" | mysql #{db_access_opts}`.strip.split("\n")[1..-1] # First line is column header.
      @drone_config.keys.find_all { |db| !existing_dbs.include?(db) }
    end

    def detect_databases_needing_schema_reload
      needing_schema = []
      @drone_config.each do |db, opts|
        if opts[:create_database]
          needing_schema << db
        else
          needing_schema << db if dev_schema_md5 != get_schema_md5(db)
        end
      end
      needing_schema
    end

    def dev_schema_md5
      @dev_schema_md5 ||= `cat #{Swarm::Util.escape_path(Swarm.schema_dump_path)} | #{SCHEMA_SANITIZATION_SED} | #{MD5_CMD}`.strip
    end

    def get_schema_md5(db)
      `mysqldump --quick --no-data #{db_access_opts} #{db} | #{SCHEMA_SANITIZATION_SED} | #{MD5_CMD}`.strip
    end

    def dump_schema
      debug("Dumping schema...")
      system "mysqldump --quick --no-data #{db_access_opts} #{test_db} > #{Swarm::Util.escape_path(Swarm.schema_dump_path)}"
    end

    def update_schema
      return if schema_migration_in_database == schema_migrations_in_file_system
      # this is now done in the rake file
      debug("rake db:schema:load...")
      # system "rake db:schema:load RAILS_ENV=test"
    end

    def schema_migration_in_database
      db_migrations = []
      ActiveRecord::Base.connection.execute("select * from #{test_db}.schema_migrations").each{|a| db_migrations << a.first}
      db_migrations
    end

    def test_db
      ActiveRecord::Base.configurations['test']['database']
    end

    def schema_migrations_in_file_system
      file_migrations = Dir.entries("#{@project_root}/db/migrate/").select{|file| file =~ /\d{12}/ }.map{|name| name[0..13] }
    end

    def choose_formatter
      @formatter = case ENV['FORMAT']
      when 'yaml'
        Formatter::YAMLFormatter.new(voice)
      else
        Formatter::FailFastProgressFormatter.new(voice)
      end
    end

    def voice
      @voice ||= Voice.new
    end

    def start_server
      FileUtils.rm(Swarm.socket_path) if File.exists?(Swarm.socket_path)
      @server = UNIXServer.new(Swarm.socket_path)
      yield
      @num_drones.times do |drone_id|
        begin
          drone_socket = @server.accept_nonblock
          start_drone_handler(drone_id, drone_socket)
        rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
          IO.select([@server])
          retry
        end
      end
    end

    def start_drone_handler(drone_id, downlink)
      Thread.start do
        loop do
          begin
            directive = Directive.interpret(downlink.gets('end_directive'))
            case directive
            when Directive::TestFailed
              @formatter.test_failed(directive.filename, directive.detail)
            when Directive::TestPassed
              @formatter.test_passed
            when Directive::TestUndefined
              @formatter.test_undefined(directive.detail)
            when Directive::TestSkipped
              @formatter.test_skipped
            when Directive::TestPending
              @formatter.test_pending(directive.detail)
            when Directive::Runtime
              @formatter.file_runtime(directive.runtime, directive.file)
            when Directive::Ready
              notify_first_drone_ready

              begin
                file = @queue.pop(true)
                file_processed(drone_id, file)
                downlink.puts(Directive.prepare(Directive::Exec.new(:file => file)))
              rescue ThreadError
                debug("Queue empty, sending Directive::Quit")
                downlink.puts(Directive.prepare(Directive::Quit))
                break
              end
            end
          rescue Exception => e
            puts e.message
            puts e.backtrace.join("\n") if e.backtrace
          end
        end
      end
    end

    def describe_processed_files
      processed_files.each do |drone_id, files|
        puts "\nDrone #{drone_id}:\n"
        files.each_with_index { |file, i| puts "#{i}. #{file}" }
      end
    end

    def file_processed(drone_id, file)
      processed_files[drone_id] ||= []
      processed_files[drone_id] << file
    end

    def processed_files
      @processed_files ||= {}
    end

    def notify_first_drone_ready
      return if @notified
      @formatter.started
      @notified = true
    end

    def populate_queue
      @queue = Queue.new
      order_by_runtime(Swarm.files).each { |file| @queue.push(file) }
    end

    def deploy_drones
      Drone.pilot.prepare
      @drone_config.each { |db, opts| deploy_drone(db, opts) }
    end

    def deploy_drone(db, options)
      fork { Drone.deploy(options.merge(:database => db)) }
    end

    def load_environment
      # require File.join(Rails.root, 'config', 'boot')
      require File.join(Rails.root, 'config', 'environment')
      # require File.join(Rails.root, 'config', 'environments', Rails.env)
      load File.join(Rails.root, 'config', 'application.rb')
    end

    def detect_cores
      logical_cpu_count = case RUBY_PLATFORM
      when /darwin/
        `/usr/bin/hostinfo` =~ /(\d+) processors are logically available/ and $1
      when /linux/
        `cat /proc/cpuinfo | grep processor | wc -l`
      else
        raise "Swarm doesn't know how to detect the number of CPUs for #{RUBY_PLATFORM}"
      end.strip.to_i
      debug("Detected #{logical_cpu_count} logical CPUs")
      logical_cpu_count
    end

    private

    def db_access_opts
      return @db_access_opts if defined? @db_access_opts
      str = []
      str << "-u #{@base_environment_configuration["username"]}" if @base_environment_configuration["username"]
      str << "-h #{@base_environment_configuration["host"]}" if @base_environment_configuration["host"]
      str << "-p#{@base_environment_configuration["password"]}" if @base_environment_configuration["password"]
      @db_access_opts = str.join ' '
    end
  end
end
