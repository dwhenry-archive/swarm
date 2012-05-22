require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Swarm" do
  it 'single passing spec' do
    `bundle exec rake swarm:specs[spec/single_pass] NUM_DRONES=1 `.should =~ /^\.\n/
  end

  it 'single failing spec' do
    `bundle exec rake swarm:specs[spec/single_fail] NUM_DRONES=1`.should =~ /^1 failed:\n/
  end
end
