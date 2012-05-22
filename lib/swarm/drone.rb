module Swarm
  class Drone
    attr_reader :name

    include Singleton
    include Utilities::OutputHelper

    def self.deploy(options)
      instance.deploy(options)
    end

    def self.pilot
      instance.pilot
    end

    def pilot
      @pilot ||= Swarm.drone_pilot.new(self)
    end

    def deploy(options)
      @options = options
      @name = "#{Process.pid}, #{@options[:database]}"

      begin
        recreate_database
        load_schema
        connect_to_database

        debug("Directive::Ready")
        relay(Directive::Ready)

        loop do
          case directive = next_directive
          when Directive::Exec
            Dir.chdir(@options[:project_root])
            pilot.exec(directive)
            relay(Directive::Ready)
          when Directive::Quit
            debug("Directive::Quit")
            break
          end
        end
      rescue SystemExit
        exit 1
      end
    end

    def relay(directive)
      begin
        uplink.write_directive directive
      rescue Errno::EPIPE
        debug("Lost uplink to queen!")
        exit 1
      end
    end

    protected

    def debug(msg)
      super("DRONE(#{@name}): #{msg}")
    end

    def recreate_database
      return if @options[:create_database] == false
      debug("Recreating #{@options[:database]}...")
      @options[:instance].recreate_database(@options)
    end

    def load_schema
      return if @options[:reload_schema] == false
      debug("Loading schema into #{@options[:database]}...")
      @options[:instance].load_schema(@options)
    end

    def connect_to_database
      ActiveRecord::Base.connection.disconnect!
      db_config = ActiveRecord::Base.configurations[Rails.env].merge('database' => @options[:database])
      ActiveRecord::Base.establish_connection(db_config)
    end

    def next_directive
      uplink.get_directive
    end

    def uplink
      @uplink ||= Comms.uplink
    end
  end
end
