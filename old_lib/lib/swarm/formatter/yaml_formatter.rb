module Swarm
  module Formatter
    class YAMLFormatter < Formatter::Base

      def completed
        # Don't need to acquire the mutex here.
        @results[:runtime] = runtime
        output(YAML.dump(@results))
      end
    end
  end
end
