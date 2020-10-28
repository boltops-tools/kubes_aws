require "aws-sdk-eks"
require "aws-sdk-iam"

module KubesAws
  module AwsServices
    extend Memoist

    def eks
      Aws::EKS::Client.new
    end
    memoize :eks

    def iam
      Aws::IAM::Client.new
    end
    memoize :iam

    def secrets
      Aws::SecretsManager::Client.new
    end
    memoize :secrets

    def ssm
      Aws::SSM::Client.new
    end
    memoize :ssm
  end
end
