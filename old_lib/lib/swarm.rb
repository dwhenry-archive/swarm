require 'singleton'

require 'rubygems'
require 'database_cleaner'
require 'rspec'
require 'cucumber'
require 'base64'
require 'yaml'

begin
  require 'term/ansicolor'
rescue LoadError
end

$:.unshift(File.dirname(__FILE__))

require 'swarm/output_helper'
require 'swarm/directive'
require 'swarm/drone'
require 'swarm/voice'
require 'swarm/queen'
require 'swarm/spec_formatter'
require 'swarm/feature_formatter'
require 'swarm/pilot/base'
require 'swarm/pilot/spec_pilot'
require 'swarm/pilot/feature_pilot'
require 'swarm/formatter/base'
require 'swarm/formatter/fail_fast_progress_formatter'
require 'swarm/formatter/yaml_formatter'
require 'swarm/util'

module Swarm
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
    @num_drones = num_drones
  end
  
  def self.num_drones
    @num_drones
  end

  def self.mobilise
    Queen.rule
  end
end
