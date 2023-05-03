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

    def issuer_host(value=nil)
      if value.nil? # reader method
        @issuer_host || issuer_url.sub('https://','')
      else # setter method
        @issuer_host = value
      end
    end

    def trust_policy
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
    rescue Aws::EKS::Errors::ResourceNotFoundException => e
      logger.info "ERROR #{e.class}: #{e.message}".color(:red)
      logger.info <<~EOL
        The cluster #{cluster} does not exist.
        Please specify the cluster name. Example:

        .kubes/aws/iam_role.rb

            cluster "dev"

        Kubes can also discover the cluster name with kubectl.
        You have to configure ~/.kube/config with the proper context for this to work.
        In that case, you would remove the cluster setting in the .kubes/aws/iam_role.rb file.

        #{issuer_url_message}
        EOL
        exit 1
    end
    memoize :issuer_url

    def issuer_url_message
      <<~EOL
      The EKS cluster name is used to generate the trust policy.
      Specifically, the trust policy uses the OIDC issuer URL.
      You can also bypass this conventional logic by setting the issuer_host.

      .kubes/aws/iam_role.rb

          issuer_host "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"

      Docs: https://kubes.guru/docs/features/aws/iam-role/
      EOL
    end

    # Attempts to infer the EKS cluster name using kubectl
    def infer_cluster
      command = "kubectl config view --minify --output 'jsonpath={..contexts..context.cluster}'"
      out = `#{command}`
      success = $?.success?
      name = out.split('/').last
      if !success or name.blank?
        logger.error "ERROR: Kubes unable to discover the cluster name with kubectl.".color(:red)
        logger.info <<~EOL
          You have to configure ~/.kube/config with the proper context for discovery to work.

          Or you can set the cluster name in .kubes/aws/iam_role.rb file.

          .kubes/aws/iam_role.rb

              cluster "dev"

          #{issuer_url_message}
        EOL
        exit 1
      end
      name
    end
  end
end