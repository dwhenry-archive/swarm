module Swarm
  module Formatter
    class FailFastProgressFormatter < Formatter::Base
      def output_passed
        output(green('.'))
      end

      def output_failed(detail)
        output(red("\n\n#{detail}\n\n"))
      end

      def output_pending(detail)
        output(yellow("\n\n#{detail}\n\n"))
      end

      def output_skipped
        output(cyan('_'))
      end

      def completed
        output("\n\nRuntime: #{runtime}\n")
        
        # describe(:failed, :red)
        describe(:pending, :yellow)
        describe_slow_files
        list_filenames(:failed, :red)
      end

      protected
      
      def describe_slow_files
        if Swarm.num_slow_files > 0
          slow = @results[:runtimes].sort_by(&:first).reverse[0..Swarm.num_slow_files-1]
          if !slow.empty?
            output("\nTop #{Swarm.num_slow_files} slowest files:\n")
            slow.each do |runtime, file|
              runtime = "%.2f" % runtime
              file = file.split(@project_root).last
              file = file[1..-1] if file.starts_with?("/")
              output "#{red("%06g" % runtime)} #{file}\n"
            end
          end
        end
      end
      
      def describe(what, colour)
        if (@results[:stats][what] > 0)
          output("\n#{@results[:stats][what]} #{what}:\n")
          @results[what].each do |filename, line|
            output(send(colour, line) + "\n\n")
          end
          output("\n")
        end
      end
      
      def list_filenames(what, colour)
        if (@results[:stats][what] > 0)
          output("\n#{@results[:stats][what]} #{what}:\n")
          @results[what].each do |filename, line|
            name = filename.split("\n").detect{|l| l =~ /:\d+$/} || filename.split("\n").first
            output("#{send(colour, name)}\n")
          end
          output("\n")
        end
      end        

      if defined?(Term)
        include Term::ANSIColor
      else
        def yellow(str)
          str
        end

        def red(str)
          str
        end

        def green(str)
          str
        end

        def cyan(str)
          str
        end
      end
    end
  end
end
