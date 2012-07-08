module Swarm
  class Database
    attr_reader :config

    SCHEMA_SANITIZATION_SED = "sed -e 's/ AUTO_INCREMENT=[0-9]*//' -e 's/--.*//'"
    MD5_CMD = RUBY_PLATFORM =~ /darwin/ ? 'md5' : 'md5sum'

    def self.select
      adapter = ActiveRecord::Base.connection.instance_values["config"][:adapter]
      case adapter
      when 'sqlite3'
        require "swarm/database/sqlite3"
        Sqlite3.new
      when 'mysql', 'mysql2'
        require "swarm/database/mysql"
        Mysql.new
      else
        raise "Unknown database adapter type: #{adapter}"
      end
    end

    def initialize
      @environment_name = Rails.env
      @configuration = ActiveRecord::Base.configurations[@environment_name].dup
      @name = clean_name(@configuration['database'])
      @project_root = Rails.root
    end

    def setup(instances)
      @instances = instances
      build_drone_deployment_config
    end

    def clean_name(database_name)
      database_name
    end

    def default_config
      {
        :create_database => false,
        :reload_schema => false,
        :project_root => @project_root,
        :instance => self
      }
    end

    def build_drone_deployment_config
      @config = {}
      (@instances).times do |i|
        @config["#{@name}_#{i + 1}"] = default_config
      end

      detect_databases_needing_create.each do |db|
        @config[db][:create_database] = true
        @config[db][:reload_schema] = true
      end

      detect_databases_needing_schema_reload.each do |db|
        @config[db][:reload_schema] = true
      end
      Swarm::Debug(@config.inspect)
    end


    def detect_databases_needing_schema_reload
      @config.keys
    end

    def detect_databases_needing_create
      @config.keys
    end

    def dev_schema_md5
      @dev_schema_md5 ||= `cat #{schema_dump_path} | #{SCHEMA_SANITIZATION_SED} | #{MD5_CMD}`.strip
    end

    def schema_dump_path
      Swarm::Utilities::Util.escape_path(Swarm.schema_dump_path)
    end
  end
end