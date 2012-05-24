require 'ruby-debug'

module Swarm
  class Queen
    include Singleton
    include Utilities::OutputHelper

    attr_reader :formatter

    def self.rule
      instance.rule
    end

    def initialize
      load_environment
      @db = Swarm::Database.select
      @runtimes = []
      choose_formatter
    end

    def rule
      set_number_of_drones
      @db.setup(Swarm.num_drones)
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

    private
    def load_environment
      # require File.join(Rails.root, 'config', 'boot')
      require File.join(Rails.root, 'config', 'environment')
      # require File.join(Rails.root, 'config', 'environments', Rails.env)
      load File.join(Rails.root, 'config', 'application.rb')
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
      return if Swarm.num_drones
      cores = detect_cores
      Swarm.num_drones = (cores * 2 - (cores / 2))

      drone_str = Swarm.num_drones == 1 ? "drone" : "drones"
      debug("Starting #{Swarm.num_drones} #{drone_str}")
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
      @voice ||= Utilities::Voice.new
    end

    def start_server
      Comms.open
      yield
      Swarm.num_drones.times do |drone_id|
        begin
          start_drone_handler(drone_id)
        rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
          IO.select([Comms.server])
          retry
        end
      end
    end

    def start_drone_handler(drone_id)
      downlink = Comms.downlink
      Thread.start do
        loop do
          begin
            case directive = downlink.get_directive
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
                downlink.write_directive Directive::Exec.new(:file => file)
              rescue ThreadError
                debug("Queue empty, sending Directive::Quit")
                downlink.write_directive Directive::Quit
                break
              end
            end
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
      @db.config.each { |db, opts| deploy_drone(db, opts) }
    end

    def deploy_drone(db, options)
      fork { Drone.deploy(options.merge(:database => db)) }
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

  end
end
