module Swarm
  module OutputHelper
    def self.included(base)
      base.class_eval do
        include InstanceMethods
        extend ClassMethods
      end
    end

    module InstanceMethods
      def debug(msg)
        self.class.debug(msg)
      end
    end

    module ClassMethods
      def debug(msg)
        if Swarm.debug?
          $stdout.write("DEBUG: #{msg}\n")
          $stdout.flush
        end
      end
    end
  end
end
