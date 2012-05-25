module Swarm
  module Pilot
    class Base
      include Utilities::OutputHelper
      def initialize(drone)
        @drone = drone
      end

      def drone
        @drone
      end

      def test_undefined(detail)
        relay(Directive::TestUndefined.new(:detail => detail))
      end

      def test_failed(filename, detail)
        relay(Directive::TestFailed.new(:filename => filename, :detail => detail))
      end

      def test_pending(detail)
        relay(Directive::TestPending.new(:detail => detail))
      end

      def test_passed
        relay(Directive::TestPassed)
      end

      def test_skipped
        relay(Directive::TestSkipped)
      end

      def prepare
      end

      def relay(directive)
        drone.uplink.relay(directive)
      end

      protected

      def run_and_relay_runtime(directive)
        started_at = Time.now
        yield
        relay(Directive::Runtime.new(:runtime => Time.now - started_at, :file => directive.file))
      end
    end
  end
end
