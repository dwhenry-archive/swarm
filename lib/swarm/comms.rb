module Swarm
  class Comms
    class << self
      def open
        instance
      end

      def server
        instance.server
      end

      def downlink
        ServerSide.new(server)
      end

      def uplink
        ClientSide.new
      end

    private

      def instance
        @instance ||= new
      end
    end

    def server
      @server
    end

  private
    def initialize
      @server = create_server
    end

    def create_server
      FileUtils.rm(path) if File.exists?(path)
      UNIXServer.new(path)
    end

    def path
      Swarm.socket_path
    end

    class Link
      include Utilities::OutputHelper

      def get_directive
        Directive.interpret(
          @link.gets(Swarm::Directive::END_OF_MESSAGE_STRING)
        )
      end

      def write_directive(directive)
        @link.puts(
          directive.prepare
        )
      end

      def relay(directive)
        begin
          write_directive directive
        rescue Errno::EPIPE
          debug("Lost uplink to queen!")
          exit 1
        end
      end
    end

    class ClientSide < Link
      def initialize
        @link = UNIXSocket.open(Swarm.socket_path)
      end
    end

    class ServerSide < Link
      def initialize(server)
        @link = server.accept_nonblock
      end
    end
  end
end
