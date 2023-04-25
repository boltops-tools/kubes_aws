require "aws_data"

class KubesAws::Cfn::IamRole
  module TrustPolicy
    extend Memoist
    include KubesAws::Services # for eks client

    # These variables can be set to override the default conventinons:
    # Original docs: https://kubes.guru/docs/helpers/aws/iam-role/
    #
    #   @cluster @namespace @ksa
    #
    # In the .kubes/aws/iam_role.rb DSL, you can use the method setter methods:
    #
    #   cluster "dev"
    #   namespace "demo-dev"
    #   ksa "demo"
    #
    # You can also set instance variable directly:
    # Note: This instance variable setting is not recommended and may be removed.
    # It is better to use the setter methods below.
    #
    #   @cluster = "dev"
    #   @namespace = "demo-dev"
    #   @ksa = "demo"
    #
    def cluster(value=nil)
      if value.nil? # reader method
        @cluster || infer_cluster
      else # setter method
        @cluster = value
      end
    end
    def namespace(value=nil)
      if value.nil? # reader method
        @namespace || [Kubes.app, Kubes.env, Kubes.extra].compact.join('-')
      else # setter method
        @namespace = value
      end
    end
    def ksa(value=nil)
      if value.nil? # reader method
        @ksa || Kubes.app
      else # setter method
        @ksa = value
      end
    end

    def trust_policy
      issuer_host = issuer_url.sub('https://','')
      provider_arn = "arn:aws:iam::#{aws.account}:oidc-provider/#{issuer_host}"
      <<~JSON
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Principal": {
              "Federated": "#{provider_arn}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
              "StringEquals": {
                "#{issuer_host}:sub": "system:serviceaccount:#{namespace}:#{ksa}"
              }
            }
          }
        ]
      }
      JSON
    end

    def issuer_url
      resp = eks.describe_cluster(name: cluster)
      resp.cluster.identity.oidc.issuer
    end
    memoize :issuer_url

    # Attempts to infer the EKS cluster name using kubectl
    def infer_cluster
      command = "kubectl config view --minify --output 'jsonpath={..contexts..context.cluster}'"
      out = `#{command}`
      success = $?.success?
      name = out.split('/').last
      if !success or name.blank?
        logger.error <<~EOL.color(:red)
          ERROR: unable to determine EKS cluster name. Please specify it in:

              KubesAws::IamRole.new

        EOL
        exit 1
      end
      name
    end
  end
end