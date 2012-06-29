require 'rails_support_hacks'

require 'singleton'
require 'rubygems'
require 'rspec'
require 'cucumber'
require 'json'
require 'yaml'

begin
  require 'term/ansicolor'
rescue LoadError
end

$:.unshift(File.dirname(__FILE__))

require 'swarm/utilities/voice'
require 'swarm/utilities/output_helper'
require 'swarm/utilities/util'


require 'swarm/comms'
require 'swarm/queen'
require 'swarm/database'
require 'swarm/directive'
require 'swarm/drone'
require 'swarm/files'

require 'swarm/runner/spec'
require 'swarm/runner/feature'

require 'swarm/handler'
require 'swarm/record'

require 'swarm/pilot/base'
require 'swarm/pilot/spec_pilot'
require 'swarm/pilot/feature_pilot'

require 'swarm/formatter/base'
require 'swarm/formatter/fail_fast_progress_formatter'
require 'swarm/formatter/yaml_formatter'

require 'rake'
# load 'swarm/tasks/swarm.rake'

rake_tasks do
  load 'swarm/tasks/swarm.rake'
  # load "rspec/rails/tasks/rspec.rake"
end

module Swarm
  class Debug
    include Swarm::Utilities::OutputHelper
  end

  def self.Debug(msg)
    Swarm::Debug.debug(msg)
  end

  def self.debug=(bool)
    @debug = bool
  end

  def self.debug?
    !!@debug
  end

  def self.drone_pilot=(pilot_class)
    @pilot_class = pilot_class
  end

  def self.drone_pilot
    @pilot_class
  end

  def self.files=(files)
    @files = files
  end

  def self.files
    @files
  end

  # If you have any specs that need to be run non-concurrently, put them in
  # here.  They'll be run before all the rest.
  def self.series_files=(files)
    @series_files = files
  end

  def self.series_files
    @series_files
  end

  def self.runtimes_dir
    File.join(Rails.root, 'tmp', 'swarm_runtimes')
  end

  def self.schema_dump_path
    File.join(Rails.root, 'tmp', 'schema_dump.swarm')
  end

  def self.socket_path
    File.join(Rails.root, 'tmp', 'swarm.socket')
  end

  def self.num_slow_files=(num)
    @num_slow_files = num
  end

  def self.num_slow_files
    @num_slow_files || 5
  end

  def self.num_drones=(num_drones)
    @num_drones = num_drones.to_i
  end

  def self.num_drones
    @num_drones
  end

  def self.mobilise
    Queen.rule
  end
end
