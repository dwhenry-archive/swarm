module Swarm
  module Formatter
    class Base
      def initialize(voice)
        @voice = voice
        @results = {:stats => {:passed => 0, :failed => 0, :skipped => 0, :pending => 0, :undefined => 0}, :failed => [], :pending => [], :runtimes => [], :undefined => []}
        @mutex = Mutex.new
      end
      
      def any_failed?
        !@results[:failed].empty?
      end

      def any_undefined?
        !@results[:undefined].empty?
      end

      def test_passed
        increment(:passed)
        output_passed
      end

      def test_pending(detail)
        increment(:pending)

        @mutex.synchronize do
          @results[:pending] << detail
        end
        
        output_pending(detail)
      end

      def test_failed(filename, detail)
        increment(:failed)

        @mutex.synchronize do
          @results[:failed] << [filename, detail]
        end

        output_failed(detail)
      end

      def test_undefined(detail)
        increment(:undefined)

        @mutex.synchronize do
          @results[:undefined] << detail
        end
        
        output_failed(detail)
      end

      def test_skipped
        increment(:skipped)
        output_skipped
      end
      
      def file_runtime(runtime, file)
        @mutex.synchronize do
          @results[:runtimes] << [runtime, file]
        end
      end

      def completed
      end

      def started
        @started_at ||= Time.now
      end
      
      def runtimes
        @results[:runtimes]
      end

      protected

      def output_passed
      end
      
      def output_pending
      end
      
      def output_skipped
      end
      
      def output_failed
      end

      def increment(counter)
        @mutex.synchronize do
          @results[:stats][counter] += 1
        end
      end

      def runtime
        Time.now - @started_at
      end

      def output(str)
        @voice.say(str)
      end

      def puts(str)
        raise "Use output() instead"
      end
    end
  end
end
