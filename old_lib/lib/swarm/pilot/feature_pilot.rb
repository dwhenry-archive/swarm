module Swarm
  module Pilot
    class SwarmConfiguration < ::Cucumber::Cli::Configuration
      attr_accessor :disable_support_file_loading

      [:all_files_to_load, :step_defs_to_load, :support_to_load].each do |override_method|
        define_method(override_method) do |*args|
          if self.disable_support_file_loading
            []
          else
            super(*args)
          end
        end
      end
    end

    class FeaturePilot < Pilot::Base
      def prepare
        # Some features can't handle being parallelised. Run them up front.
        # configure_runtime(['--no-profile', '--tags', '@series', '--format', 'Swarm::QueenFeatureFormatter'])
        # debug("running non concurrent features")
        # runtime.run!
        # debug("completed non-concurrent features")
      end

      def exec(directive)
        begin
          configure_runtime(['--no-profile', '--require', File.join(Rails.root, 'features'), '--strict', '--tags', '~@series', '--tags', '~@wip', '--tags', '~@completed_pending', '--format', 'Swarm::FeatureFormatter', directive.file])
          runtime.instance_variable_set('@loader', nil)
          run_and_relay_runtime(directive) { runtime.run! }
        rescue SystemExit
          exit 1
        rescue Exception => e
          detail = [e.message]
          detail << e.backtrace.join("\n")
          drone.relay(Directive::TestFailed.new(:filename => e.backtrace.first, :detail => detail.join("\n"), :encoded => false))
        end
      end

      def runtime
        @runtime ||= Cucumber::Runtime.new
      end

      def configure_runtime(args)
        output_stream = File.open('/dev/null', 'w')
        @configuration = SwarmConfiguration.new(output_stream, output_stream)
        @configuration.parse!(args)
        @configuration.disable_support_file_loading = true if @subsequent
        @subsequent = true
        runtime.configure(@configuration)
      end
    end
  end
end
