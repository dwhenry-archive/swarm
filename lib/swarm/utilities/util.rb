module Swarm
  module Utilities
    module Util
      def self.escape_path(path)
        path.gsub(' ', '\ ')
      end
    end
  end
end