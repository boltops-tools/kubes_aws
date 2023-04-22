require "aws-sdk-cloudformation"
require "aws-sdk-eks"
require "aws-sdk-iam"
require "aws-sdk-secretsmanager"
require "aws-sdk-ssm"

module KubesAws
  module Services
    extend Memoist
    include Concerns

    def cfn
      Aws::CloudFormation::Client.new
    end
    memoize :cfn

    def eks
      Aws::EKS::Client.new
    end
    memoize :eks

    def iam
      Aws::IAM::Client.new
    end
    memoize :iam

    def secretsmanager
      Aws::SecretsManager::Client.new
    end
    memoize :secretsmanager

    def ssm
      Aws::SSM::Client.new
    end
    memoize :ssm
  end
end
