require 'timeout'
# status = Timeout::timeout(5) {

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

      def close
        instance.close if server
      end

    private

      def instance
        @instance ||= new
      end
    end

    def server
      @server
    end

    def close
      @server.close
      @server = nil
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
          Swarm::Debug("Lost uplink to queen!")
          exit 1
        end
      end
    end

    class ClientSide < Link
      def initialize
        @link = UNIXSocket.open(Swarm.socket_path)
        super
      end
    end

    class ServerSide < Link
      def initialize(server)
        @link = server.accept_nonblock
        super
      rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
        IO.select([Comms.server])
        retry
      end
    end
  end
end
