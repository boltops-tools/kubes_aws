require "active_support/core_ext/string"
require "aws_data"
require "json"

module KubesAws
  class IamRole
    extend Memoist
    include Services
    include Logging
    include Prebaked

    # public method to keep: role_name
    attr_reader :role_name
    def initialize(app:, cluster:nil, namespace:nil, managed_policies: [], inline_policies: [], role_name: nil, ksa: nil)
      @app, @cluster, @managed_policies, @inline_policies = app, cluster, managed_policies, inline_policies

      # conventional names
      @ksa = ksa || @app                               # convention: app
      @namespace = namespace || "#{@app}-#{Kubes.env}" # convention: app-env
      @role_name = role_name || "#{@app}-#{Kubes.env}" # convention: app-env
      @cluster ||= infer_cluster
    end

    def call
      create_open_id_connect_provider
      create_iam_role
      add_mananged_policies
      add_inline_policies
    end

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

    def add_inline_policies
      @inline_policies.each do |policy|
        params = normalize_inline_policy(policy)
        iam.put_role_policy(params)
      end
    end

    # resp = client.put_role_policy(
    #   policy_document: "{\"Version\":\"2012-10-17\",\"Statement\":{\"Effect\":\"Allow\",\"Action\":\"s3:*\",\"Resource\":\"*\"}}",
    #   policy_name: "S3AccessPolicy",
    #   role_name: "S3Access",
    # )
    def normalize_inline_policy(policy)
      prebaked = prebaked_policies[policy]
      policy = prebaked if prebaked

      policy_document = policy[:policy_document]
      policy[:policy_document] = JSON.dump(policy_document) if policy_document.is_a?(Hash)
      policy[:role_name] = @role_name
      policy
    end

    def create_open_id_connect_provider
      open_id = OpenId.new(@cluster)
      open_id.create_provider
    end

    def create_iam_role
      return if role_exist?
      iam.create_role(
        role_name: @role_name,
        assume_role_policy_document: trust_policy,
      )
      logger.debug "Created IAM Role #{@role_name}"
    end

    def add_mananged_policies
      @managed_policies.each do |policy|
        policy_arn = normalize_managed_policy(policy)
        iam.attach_role_policy(
          role_name: @role_name,
          policy_arn: policy_arn,
        )
      end
      logger.debug "IAM Policies added to #{@role_name}"
    end

    # AmazonS3ReadOnlyAccess => arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
    def normalize_managed_policy(policy)
      if policy.include?("arn:")
        policy
      else
        "arn:aws:iam::aws:policy/#{policy}"
      end
    end

    def role_exist?
      iam.get_role(role_name: @role_name)
      true
    rescue Aws::IAM::Errors::NoSuchEntity
      false
    end

    # public method to keep: arn
    def arn
      "arn:aws:iam::#{aws_account}:role/#{@role_name}"
    end

    # public method to keep: aws_account
    def aws_account
      aws.account
    end

    def trust_policy
      issuer_host = issuer_url.sub('https://','')
      provider_arn = "arn:aws:iam::#{aws_account}:oidc-provider/#{issuer_host}"
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
                "#{issuer_host}:sub": "system:serviceaccount:#{@namespace}:#{@ksa}"
              }
            }
          }
        ]
      }
      JSON
    end

    def issuer_url
      resp = eks.describe_cluster(name: @cluster)
      resp.cluster.identity.oidc.issuer
    end
    memoize :issuer_url

    def aws
      AwsData.new
    end
    memoize :aws

    # useful to store data used later
    class_attribute :data, :role_arn
  end
end
