module Swarm
  class Handler
    include Utilities::OutputHelper

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
      @db.config.each { |db, opts| deploy_drone(db, opts) }
    end

    def deploy_drone(db, options)
      fork { Drone.deploy(options.merge(:database => db)) }
    end

    def start_thread(drone_id)
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

              begin
                file = Swarm::Files.next
                Swarm::Record.file_processed(drone_id, file)
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
  end
end