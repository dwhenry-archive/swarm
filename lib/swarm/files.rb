module Swarm
  module Files
    class << self
      def populate
        @queue = ::Queue.new
        Swarm::Record.order_by_runtime(Swarm.files).each do |file|
          @queue.push(file)
        end
      end

      def next
        @queue.pop(true)
      rescue ThreadError
        nil
      end
    end
  end
end