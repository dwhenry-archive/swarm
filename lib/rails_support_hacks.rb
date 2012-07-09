module StringExtend
  def constantize
    names = self.split('::')
    names.shift if names.empty? || names.first.empty?

    constant = Object
    names.each do |name|
      constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
    end
    constant
  end
end

if defined?(String) && !''.respond_to?(:constantize)
  String.send :include, StringExtend
end

unless defined?(Rails)
  module Rails
    def self.root
      @root ||= File.join(File.dirname(__FILE__), '..', 'test_app')
    end
  end
end