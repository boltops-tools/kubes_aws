module KubesAws
  class Cfn < Kubes::CLI::Base
    def deploy
      @template = Builder.new(@options).template
      puts "@template:"
      pp @template
    end

    def delete
      puts "delete"
    end
  end
end
