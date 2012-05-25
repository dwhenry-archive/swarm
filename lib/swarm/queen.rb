require 'ruby-debug'

module Swarm
  class Queen
    include Singleton

    attr_reader :formatter

    def self.rule
      instance.rule
    end

    def initialize
      load_environment
      @db = Swarm::Database.select
      @runtimes = []
      choose_formatter
    end

    def rule
      set_number_of_drones
      @db.setup(Swarm.num_drones)

      Swarm::Files.populate

      @formatter.start
      voice.start # not sure I like calling this a 'voice'

      Swarm::Handler.start(@formatter, @db)

      @formatter.completed
      Swarm::Record.save_runtimes(@formatter.runtimes)
      voice.stop
      Swarm::Record.describe_processed_files if Swarm.debug? || @formatter.any_failed?
      exit 1 if @formatter.any_failed? || @formatter.any_undefined?
    end

    private
    def load_environment
      # require File.join(Rails.root, 'config', 'boot')
      require File.join(Rails.root, 'config', 'environment')
      # require File.join(Rails.root, 'config', 'environments', Rails.env)
      load File.join(Rails.root, 'config', 'application.rb')
    end

    protected

    def set_number_of_drones
      return if Swarm.num_drones
      cores = detect_cores
      Swarm.num_drones = (cores * 2 - (cores / 2))

      drone_str = Swarm.num_drones == 1 ? "drone" : "drones"
      Swarm::Debug("Starting #{Swarm.num_drones} #{drone_str}")
    end

    def choose_formatter
      @formatter = case ENV['FORMAT']
      when 'yaml'
        Formatter::YAMLFormatter.new(voice)
      else
        Formatter::FailFastProgressFormatter.new(voice)
      end
    end

    def voice
      @voice ||= Utilities::Voice.new
    end

    def detect_cores
      logical_cpu_count = case RUBY_PLATFORM
      when /darwin/
        `/usr/bin/hostinfo` =~ /(\d+) processors are logically available/ and $1
      when /linux/
        `cat /proc/cpuinfo | grep processor | wc -l`
      else
        raise "Swarm doesn't know how to detect the number of CPUs for #{RUBY_PLATFORM}"
      end.strip.to_i
      Swarm::Debug("Detected #{logical_cpu_count} logical CPUs")
      logical_cpu_count
    end

  end
end
