module Swarm
  class Directive
    include Utilities::OutputHelper

    END_OF_MESSAGE_STRING = "\nend_directive"

    class DirectiveError < Exception
    end

    class Base
      def self.handle?(str)
        !!(str =~ self.const_get('REGEXP'))
      end

      def self.prepare
        new.prepare
      end

      def initialize(details={})
        details.delete('class_name')
        @details = details
      end

      def self.interpret(str)
        new(*str.match(self.const_get('REGEXP')).captures)
      end

      def to_s
        "#{json}#{END_OF_MESSAGE_STRING}\n"
      end
      alias :prepare :to_s

      def json
        @details.merge('class_name' => self.class.to_s).to_json
      end

      def method_missing(mth, *args)
        return @details[mth] if @details.has_key?(mth)
        return @details[mth.to_s] if @details.has_key?(mth.to_s)
        super
      end
    end


    class Runtime < Base
      def runtime
        super.try(:to_f)
      end
    end

    class Exec < Base; end
    class TestUndefined < Base; end
    class TestFailed < Base; end
    class TestPending < Base; end
    class TestPassed < Base; end
    class TestSkipped < Base; end
    class Quit < Base; end
    class Ready < Base; end

    def self.interpret(raw_directive)
      raw_directive.strip!

      json = raw_directive.match("(.*)#{END_OF_MESSAGE_STRING}").captures.first

      hash = JSON.parse(json)
      hash['class_name'].constantize.new(hash)

    rescue => e
      raise DirectiveError, "Directive #{raw_directive.inspect}\n#{e.message}"
    end
  end
end