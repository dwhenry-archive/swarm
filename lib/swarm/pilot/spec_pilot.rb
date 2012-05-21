module Swarm
  module Pilot
    class SpecPilot < Pilot::Base
      def prepare
        RSpec::Core::Runner.disable_autorun!

        # Load some constants before we fork to take advantage of Copy On Write.
        RSpec::Core::ConfigurationOptions
        # Some specs can't handle being parallelised. Run them up front.
        if Swarm.series_files
          RSpec.configure do |config|
            config.add_formatter(Swarm::Handler::Spec)
          end
          debug("running non-concurrent specs")
          RSpec::Core::Runner.run(Swarm.series_files)
          debug("completed non-concurrent specs")
        end
      end

      def exec(directive)
        begin
          RSpec.configure do |config|
            config.add_formatter(Swarm::Handler::Spec)
          end
          run_and_relay_runtime(directive) { RSpec::Core::Runner.run([directive.file]) }
        rescue SystemExit
          exit 1
        rescue Exception => e
          debug("Drone #{drone.name} handling error: #{e.inspect}")
          detail = [e.message]
          detail << "On file: #{directive.file}"
          detail << e.backtrace.take_while{|line| line !~ %r{lib/swarm/lib/swarm/pilot/spec_pilot.rb} }.join("\n")
          @drone.relay(Directive::TestFailed.new(:filename => directive.file, :detail => detail.join("\n")))
        end
      end
    end
  end
end
