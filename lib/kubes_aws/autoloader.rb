require "zeitwerk"

module KubesAws
  class Autoloader
    class Inflector < Zeitwerk::Inflector
      def camelize(basename, _abspath)
        map = { cli: "CLI", ssm: "SSM", version: "VERSION" }
        map[basename.to_sym] || super
      end
    end

    class << self
      def setup
        loader = Zeitwerk::Loader.new
        loader.inflector = Inflector.new
        lib = File.expand_path("../", __dir__)
        loader.push_dir(lib)
        loader.setup
      end
    end
  end
end
