module Swarm
  class Comms
    class << self
      def open
        @instance ||= new
      end

      def server
        @instance.server
      end

      def downlink(override=nil)
        Downlink.new(override || server)
      end

      def uplink
        Uplink.new
      end
    end

    def initialize
      @server = create_server
    end

    def server
      @server
    end

    def create_server
      FileUtils.rm(path) if File.exists?(path)
      UNIXServer.new(path)
    end

  private

    def path
      Swarm.socket_path
    end

    class Link
      def get_directive
        Directive.interpret(
          @link.gets(Swarm::Directive::END_OF_MESSAGE_STRING)
        )
      end

      def write_directive(directive)
        @link.puts(
          Directive.prepare(directive)
        )
      end
    end

    class Uplink < Link
      def initialize
        @link = UNIXSocket.open(Swarm.socket_path)
      end
    end

    class Downlink < Link
      def initialize(server)
        @link = server.accept_nonblock
      end
    end
  end
end
