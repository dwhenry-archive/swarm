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
        @drone.relay(Directive::TestUndefined.new(:detail => detail))
      end

      def test_failed(filename, detail)
        @drone.relay(Directive::TestFailed.new(:filename => filename, :details => detail))
      end

      def test_pending(detail)
        @drone.relay(Directive::TestPending.new(:detail => detail))
      end

      def test_passed
        @drone.relay(Directive::TestPassed)
      end

      def test_skipped
        @drone.relay(Directive::TestSkipped)
      end

      def prepare
      end

      protected

      def run_and_relay_runtime(directive)
        started_at = Time.now
        yield
        @drone.relay(Directive::Runtime.new(:runtime => Time.now - started_at, :file => directive.file))
      end
    end
  end
end
