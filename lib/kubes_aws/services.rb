require "aws-sdk-cloudformation"
require "aws-sdk-ecr"
require "aws-sdk-efs"
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

    def ecr
      Aws::ECR::Client.new
    end
    memoize :ecr

    def efs
      Aws::EFS::Client.new
    end
    memoize :efs

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
