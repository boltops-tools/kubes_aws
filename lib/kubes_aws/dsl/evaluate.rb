module KubesAws::Dsl
  module Evaluate
    include DslEvaluator
    include Interface

    def lookup_kubes_file(name)
      root = ".kubes/aws/#{name}"
      app_root = ".kubes/aws/#{Kubes.app}/#{name}"
      if File.exist?(app_root)
        app_root
      elsif File.exist?(root)
        root
      end
    end
  end
end
