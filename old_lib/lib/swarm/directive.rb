module Swarm
  class Directive
    include OutputHelper

    class DirectiveError < Exception
    end

    class Base
      def self.handle?(str)
        !!(str =~ self.const_get('REGEXP'))
      end

      def initialize(*args)
      end

      def self.interpret(str)
        new(*str.match(self.const_get('REGEXP')).captures)
      end

      def to_s
        raise NotImplementedError
      end
    end

    class Exec < Base
      REGEXP = /^exec (.+) end_directive$/
      attr_reader :file

      def initialize(file)
        @file = file
      end

      def to_s
        "exec #{@file} end_directive"
      end
    end

    class Runtime < Base
      attr_reader :file
      REGEXP = /^runtime ([\d]*\.?[\d]*) (.*) end_directive/
      
      def initialize(runtime, file)
        @runtime = runtime
        @file = file
      end
      
      def runtime
        @runtime.to_f if @runtime
      end
      
      def to_s
        "runtime #{@runtime} #{@file} end_directive"
      end
    end

    class TestUndefined < Base
      attr_reader :detail
      REGEXP = /^test_undefined ([\s\w\+\/=]+) end_directive$/

      def initialize(detail, opts = {})
        opts = {:encoded => true}.merge(opts)
        @detail = opts[:encoded] ? decode(detail) : detail
      end

      def to_s
        "test_undefined #{encode(@detail)} end_directive"
      end

      protected

      def encode(str)
        Base64.encode64(str)
      end

      def decode(str)
        Base64.decode64(str)
      end
    end

    class TestFailed < Base
      attr_reader :detail, :filename
      REGEXP = /^test_failed (.+?) \|\| ([\s\w\+\/=]+) end_directive$/m

      def initialize(filename, detail, opts = {})
        opts = {:encoded => true}.merge(opts)
        @detail = opts[:encoded] ? decode(detail) : detail
        @filename = opts[:encoded] ? decode(filename) : filename
      end

      def to_s
        "test_failed #{encode(@filename)} || #{encode(@detail)} end_directive"
      end

      protected

      def encode(str)
        Base64.encode64(str)
      end

      def decode(str)
        Base64.decode64(str)
      end
    end

    class TestPending < Base
      attr_reader :detail
      REGEXP = /^test_pending ([\s\w\+\/=]+) end_directive$/

      def initialize(detail, opts = {})
        opts = {:encoded => true}.merge(opts)
        @detail = opts[:encoded] ? decode(detail) : detail
      end

      def to_s
        "test_pending #{encode(@detail)} end_directive"
      end

      protected

      def encode(str)
        Base64.encode64(str)
      end

      def decode(str)
        Base64.decode64(str)
      end
    end

    class TestPassed < Base
      REGEXP = /^test_passed end_directive$/

      def to_s
        'test_passed end_directive'
      end
    end

    class TestSkipped < Base
      REGEXP = /^test_skipped end_directive$/

      def to_s
        'test_skipped end_directive'
      end
    end

    class Quit < Base
      REGEXP = /^quit end_directive$/

      def to_s
        'quit end_directive'
      end
    end
    
    class Ready < Base
      REGEXP = /^ready end_directive$/

      def to_s
        'ready end_directive'
      end
    end

    def self.prepare(directive)
      (directive.is_a?(Class) ? directive.new : directive).to_s
    end

    def self.interpret(raw_directive)
      raw_directive.strip!
      [Ready, Quit, Exec, TestPassed, TestFailed, TestSkipped, TestPending, TestUndefined, Runtime].each do |directive|
        return directive.interpret(raw_directive) if directive.handle?(raw_directive)
      end
      raise DirectiveError, "Unknown directive #{raw_directive.inspect}"
    end
  end
end