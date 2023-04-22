module KubesAws::Dsl
  module Evaluate
    include DslEvaluator
    include Interface

    def lookup_kubes_file(name)
      [".kubes", @options[:type], name].compact.join("/")
    end
  end
end
