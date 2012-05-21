module Swarm
  class Database
    class Sqlite3 < Swarm::Database
      def detect_databases_needing_create
        existing_dbs = Dir[File.join(@project_root, 'db', '*.sqlite3')].map do |n|
          n.split("/")[-2..-1].join('/')
        end
        @config.keys - existing_dbs
      end

      def recreate_database(options)
        if File.exists?(File.join(Rails.root, options[:database]))
          system("rm #{File.join(Rails.root, options[:database])}")
        end
        system("cp #{Rails.root}/{#{@name},#{options[:database]}}")
      end

      def load_schema(options)
        recreate_database(options)
      end
    end
  end
end
