require 'spec_helper'

describe Swarm::Comms do
  before { Swarm::Comms.instance_variable_set('@instance', nil) }

  describe '#open' do
    it 'create a new UNIXServer instance' do
      UNIXServer.should_receive(:new).with(Swarm.socket_path)
      Swarm::Comms.open
    end
  end

  describe '#downlink' do
    let(:server) { mock(:server) }
    let(:comms) { mock(:comms, :server => server) }
    before { Swarm::Comms.stub(:new => comms) }

    it 'creates a new server side communication object' do
      Swarm::Comms::ServerSide.should_receive(:new).with(server)
      Swarm::Comms.downlink
    end
  end

  describe '#uplink' do
    it 'creates a new client side communication object' do
      Swarm::Comms::ClientSide.should_receive(:new)
      Swarm::Comms.uplink
    end
  end
end

describe Swarm::Comms::ServerSide do
  subject { Swarm::Comms::ServerSide.new(server) }

  let(:link) { mock(:link, :gets => 'read directive') }
  let(:server) { mock(:server, :accept_nonblock => link) }
  let(:directive) { mock(:directive, :prepare => 'directive string') }

  before { Swarm::Directive.stub(:interpret => directive) }

  it 'retrieves the link from the server object' do
    server.should_receive(:accept_nonblock)
    subject
  end

  it 'can can have directives written to it' do
    link.should_receive(:puts).with('directive string')
    subject.write_directive(directive)
  end

  describe '#relay' do
    it 'writes the directive' do
      link.should_receive(:puts).with('directive string')
      subject.relay(directive)
    end

    it 'exits the code if connection to socket lost' do
      link.should_receive(:puts).and_raise(Errno::EPIPE)
      expect { subject.relay(directive) }.to raise_error(SystemExit)
    end
  end

  it 'can read a directive from the it' do
    Swarm::Directive.should_receive(:interpret).with('read directive')
    link.should_receive(:gets)
    subject.get_directive.should == directive
  end
end

describe Swarm::Comms::ClientSide do

  let(:link) { mock(:link, :gets => 'read directive') }
  let(:server) { mock(:server, :accept_nonblock => link) }
  let(:directive) { mock(:directive, :prepare => 'directive string') }

  before do
    Swarm::Directive.stub(:interpret => directive)
    UNIXSocket.stub(:open => link)
  end

  it 'opends a new link to thesocket' do
    UNIXSocket.should_receive(:open).with(Swarm.socket_path)
    subject
  end

  it 'can can have directives written to it' do
    link.should_receive(:puts).with('directive string')
    subject.write_directive(directive)
  end

  describe '#relay' do
    it 'writes the directive' do
      link.should_receive(:puts).with('directive string')
      subject.relay(directive)
    end

    it 'exits the code if connection to socket lost' do
      link.should_receive(:puts).and_raise(Errno::EPIPE)
      expect { subject.relay(directive) }.to raise_error(SystemExit)
    end
  end

  it 'can read a directive from the it' do
    Swarm::Directive.should_receive(:interpret).with('read directive')
    link.should_receive(:gets)
    subject.get_directive.should == directive
  end
end