module Swarm
  module Record
    class << self

      def file_processed(drone_id, file)
        processed_files[drone_id] ||= []
        processed_files[drone_id] << file
      end

      def processed_files
        @processed_files ||= {}
      end

      def describe_processed_files
        processed_files.each do |drone_id, files|
          puts "\nDrone #{drone_id}:\n"
          files.each_with_index { |file, i| puts "#{i}. #{file}" }
        end
      end

      def order_by_runtime(files)
        if File.exists?(runtimes_filename)
          files_with_runtime = File.read(runtimes_filename).split("\n")
          (files - files_with_runtime) + (files_with_runtime & files)
        else
          files
        end
      end

      def save_runtimes(runtimes)
        runtimes = runtimes.sort_by { |runtime, file| runtime }.reverse
        FileUtils.mkdir_p(Swarm.runtimes_dir)
        File.open(runtimes_filename, "w") do |fd|
          fd.puts(runtimes.map { |runtime, file| file }.join("\n"))
        end
      end

      def runtimes_filename
        File.join(Swarm.runtimes_dir, Drone.pilot.class.name.demodulize)
      end
    end
  end
end