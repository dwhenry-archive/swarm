require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Swarm" do
  it 'single passing spec - 1 drone' do
    `bundle exec rake swarm:specs[spec/single_pass] NUM_DRONES=1 `.should =~ /^\.\n/
  end

  it 'single failing spec - 1 drone' do
    `bundle exec rake swarm:specs[spec/single_fail] NUM_DRONES=1`.should =~ /^1 failed:\n/
  end

  it 'multiple passing spec - 2 drone' do
    `bundle exec rake swarm:specs[spec/multiple_pass] NUM_DRONES=2 `.should =~ /^\.\.\.\.\n/
  end

  it 'pass and fail - 1 drone' do
    results = `bundle exec rake swarm:specs[spec/pass_and_fail] NUM_DRONES=1 `
    results.should =~ /^\.\n/
    results.should =~ /^1 failed:\n/
  end

  it 'pass and fail - 2 drones' do
    results =  `bundle exec rake swarm:specs[spec/pass_and_fail] NUM_DRONES=2 `
    results.should =~ /^\.\n/
    results.should =~ /^1 failed:\n/
  end
end
