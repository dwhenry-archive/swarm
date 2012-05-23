require 'spec_helper'

describe Swarm::Directive do
  before do
    FileUtils.rm(Swarm.socket_path) if File.exists?(Swarm.socket_path)

    server
  end

  let(:server) { UNIXServer.new(Swarm.socket_path) }
  let(:downlink) { server.accept_nonblock }
  let(:uplink) { UNIXSocket.open(Swarm.socket_path) }

  let(:directive) { Swarm::Directive::Exec.new(:file => 'filename') }
  let(:second_directive) { Swarm::Directive::Exec.new(:file => 'other file') }
  let(:multiline_directive) { Swarm::Directive::TestFailed.new(:filename => 'fail', :detail => "details 1\ndetails 2") }

  it 'can see a directive across the link' do
    uplink.puts(directive.prepare)
    received = Swarm::Directive.interpret(downlink.gets(Swarm::Directive::END_OF_MESSAGE_STRING))
    received.file.should == directive.file
  end

  it 'can send multiple directives' do
    uplink.puts(directive.prepare)
    uplink.puts(second_directive.prepare)
    received = Swarm::Directive.interpret(downlink.gets(Swarm::Directive::END_OF_MESSAGE_STRING))
    second_received = Swarm::Directive.interpret(downlink.gets(Swarm::Directive::END_OF_MESSAGE_STRING))
    received.file.should == directive.file
    second_received.file.should == second_directive.file
  end

  it 'can process multiline directives' do
    uplink.puts(multiline_directive.prepare)
    received = Swarm::Directive.interpret(downlink.gets(Swarm::Directive::END_OF_MESSAGE_STRING))
    received.to_s.should == multiline_directive.to_s
  end
end