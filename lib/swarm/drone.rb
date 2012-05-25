module Swarm
  class Drone
    attr_reader :name

    include Singleton

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

      recreate_database
      load_schema
      connect_to_database

      execution_loop
    end

    def uplink
      @uplink ||= Comms.uplink
    end

    def relay(directive)
      @uplink.relay(directive)
    end

    def execution_loop
      debug("Directive::Ready")
      uplink.relay(Directive::Ready)

      Dir.chdir(@options[:project_root])

      loop do
        case directive = uplink.get_directive
        when Directive::Exec
          pilot.exec(directive)
          uplink.relay(Directive::Ready)

        when Directive::Quit
          debug("Directive::Quit")
          break
        end
      end
    end

    protected

    def debug(msg)
      Swarm::Debug("DRONE(#{@name}): #{msg}")
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
  end
end
