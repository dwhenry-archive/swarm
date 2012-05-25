module Swarm
  class Handler
    def self.start(formatter, db)
      server = new(formatter, db)
      server.start { server.deploy_drones }
      at_exit { Comms.server.close if Comms.server }
      Process.waitall
    end

    def initialize(formatter, db)
      @formatter = formatter
      @db = db
    end

    def start
      Comms.open
      yield
      Swarm.num_drones.times do |drone_id|
        begin
          start_thread(drone_id)
        rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
          IO.select([Comms.server])
          retry
        end
      end
    end

    def deploy_drones
      Drone.pilot.prepare
      @db.config.each do |db, options|
        fork { Drone.deploy(options.merge(:database => db)) }
      end
    end

    def start_thread(drone_id)
      processor = Processor.new(Comms.downlink, @formatter, drone_id)

      Thread.start do
        processor.run
      end
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end

    class Processor
      def initialize(downlink, formatter, drone_id)
        @downlink = downlink
        @formatter = formatter
        @drone_id = drone_id
      end

      def run
        until @exit do
          directive = @downlink.get_directive
          send(directive.action_name, directive)
        end
        Swarm::Debug("Queue empty, sending Directive::Quit")
        @downlink.write_directive Directive::Quit
      end

      def test_failed(directive)
        @formatter.test_failed(directive.filename, directive.detail)
      end

      def test_passed(directive)
        @formatter.test_passed
      end

      def test_undefined(directive)
        @formatter.test_undefined(directive.detail)
      end

      def test_skipped(directive)
        @formatter.test_skipped
      end

      def test_pending(directive)
        @formatter.test_pending(directive.detail)
      end

      def runtime(directive)
        @formatter.file_runtime(directive.runtime, directive.file)
      end

      def ready(directive)
        if file = Swarm::Files.next
          Swarm::Record.file_processed(@drone_id, file)
          @downlink.write_directive Directive::Exec.new(:file => file)
        else
          @exit = true
        end
      end
    end
  end
end