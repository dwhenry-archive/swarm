require 'rspec/core/formatters/base_formatter'

module Swarm
  module Handler
    class Spec < RSpec::Core::Formatters::BaseFormatter
      def test_result_handler
        Swarm::Drone.pilot
      end

      def example_failed(example)
        Swarm::Pilot::SpecPilot.debug("Fail: #{example.full_description}")
        detail = [example.full_description, example.execution_result[:exception].message]
        backtrace = example.execution_result[:exception].backtrace
        detail << format_backtrace(backtrace)
        top_of_backtrace = backtrace_line(example.full_description) + "\n" +
                           backtrace_line(example.location) + "\n" +
                           backtrace_line(example.execution_result[:exception].message) + "\n"
        test_result_handler.test_failed(top_of_backtrace, detail.join("\n"))
      end

      def example_passed(example)
        test_result_handler.test_passed
      end

      def example_pending(example)
        test_result_handler.test_pending("'#{example.full_description}' @ #{example.location}")
      end

      protected

      def format_backtrace(backtrace)
        return "" if backtrace.nil?
        valid_backtrace = backtrace.take_while{|line| line !~ %r{lib/swarm} && line !~ %r{lib/rspec/mocks} && line !~ %r{lib/rspec/core}}
        valid_backtrace.map { |line| backtrace_line(line) }.join("\n")
      end

      def backtrace_line(line)
        line.sub(/\A([^:]+:\d+)$/, '\\1')
      end
    end
  end
end