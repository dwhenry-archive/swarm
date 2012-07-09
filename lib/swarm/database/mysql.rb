module Swarm
  class Database
    class Mysql < Swarm::Database

      def setup(*args)
        update_schema
        dump_schema
        super
      end

      def detect_databases_needing_create
        existing_dbs = `echo "show databases" | mysql #{access_opts}`.strip.split("\n")[1..-1] # First line is column header.
        @config.keys - existing_dbs
      end

      def detect_databases_needing_schema_reload
        @config.keys.map do |database_name|
          if dev_schema_md5 != get_schema_md5(database_name)
            database_name
          end
        end.compact
      end

      def access_opts
        return @access_opts if defined? @access_opts
        str = []
        str << "-u #{@configuration["username"]}" if @configuration["username"]
        str << "-h #{@configuration["host"]}" if @configuration["host"]
        str << "-p#{@configuration["password"]}" if @configuration["password"]
        @access_opts = str.join ' '
      end

      def update_schema
        return # TODO: if this check required.. it doesn't do anything??
        return if schema_migration_in_database == schema_migrations_in_file_system
        # this is now done in the rake file
        Swarm::Debug("rake db:schema:load...")
        # system "rake db:schema:load RAILS_ENV=test"
      end

      def schema_migration_in_database
        db_migrations = []
        ActiveRecord::Base.connection.execute("select * from #{test_database_name}.schema_migrations").each{|a| db_migrations << a.first}
        db_migrations
      end

      def test_database_name
        clean_name(ActiveRecord::Base.configurations['test']['database'])
      end

      def schema_migrations_in_file_system
        file_migrations = Dir.entries("#{@project_root}/db/migrate/").select{|file| file =~ /\d{12}/ }.map{|name| name[0..13] }
      end

      def dump_schema
        Swarm::Debug("Dumping schema...")
        system "#{mysqldump(test_database_name)} > #{schema_dump_path}"
      end

      def get_schema_md5(database_name)
        `#{mysqldump(database_name)} | #{SCHEMA_SANITIZATION_SED} | #{MD5_CMD}`.strip
      end

      def mysqldump(database_name)
        "mysqldump --quick --no-data #{access_opts} #{database_name}"
      end

      def recreate_database(options)
        begin
          `mysqladmin #{access_opts} -f --no-beep drop #{options[:database]}`
        rescue => e
          puts "Could not drop database #{options[:database]}"
        end
        `mysqladmin #{access_opts} -f --no-beep create #{options[:database]}`
      end

      def load_schema(options)
        `mysql #{access_opts} #{options[:database]} < #{Swarm::Utilities::Util.escape_path(Swarm.schema_dump_path)}`
      end
    end
  end
end