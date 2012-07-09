namespace :swarm do
  desc "run all the specs using the swarm multi process thingo"
  task :specs, [:path] => :rails do |t, args|
    RAILS_ENV = ENV['RAILS_ENV'] = 'test' unless defined? RAILS_ENV
    require 'swarm'
    Swarm.drone_pilot = Swarm::Pilot::SpecPilot
    path = File.join(Rails.root, (args[:path] || 'spec'), '**', '*_spec.rb')
    Swarm.files = Dir[path]
    Swarm.debug = true if ENV['DEBUG'] == 'true'
    Swarm.num_drones = ENV['NUM_DRONES'] if ENV['NUM_DRONES']
    Swarm.mobilise
  end

  desc "run all the cucumber features using the swarm multi process thingo"
  task :features, [:path] => :rails do |t, args|
    RAILS_ENV = ENV['RAILS_ENV'] = 'cucumber' unless defined? RAILS_ENV
    require 'swarm'
    Swarm.drone_pilot = Swarm::Pilot::FeaturePilot
    Swarm.files = Dir[File.join(Rails.root, (args[:path] || 'features'), '**', '*.feature')]
    Swarm.debug = true if ENV['DEBUG'] == 'true'
    Swarm.num_drones = ENV['NUM_DRONES'] if ENV['NUM_DRONES']
    Swarm.mobilise
  end

  task :rails do
    require 'rails_support_hacks'
  end
end
