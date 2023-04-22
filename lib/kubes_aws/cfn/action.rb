class KubesAws::Cfn
  class Action < Kubes::CLI::Base
    include KubesAws::Services # for cloudformation client

    def deploy
    end

    def delete
    end
  end
end
