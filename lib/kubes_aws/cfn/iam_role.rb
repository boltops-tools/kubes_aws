class KubesAws::Cfn
  class IamRole < KubesAws::Dsl::Base
    include KubesAws::Dsl::IamRole
    include TrustPolicy

    def initialize(options={})
      super
      @role_path = lookup_kubes_file("iam_role.rb")
      @iam_policy = {}
    end

    def build
      load_variables
      evaluate_file(@role_path) if File.exist?(@role_path) # registers definitions to registry
      evaluate_definitions # build definitions from registry. can set: @iam_statements and @managed_policy_arns
      @properties[:AssumeRolePolicyDocument] = trust_policy # set after evaluate_file so @cluster is set
      @properties[:Policies] = [{
        PolicyName: "KubesAwsManagedPolicy",
        PolicyDocument: {
          Version: "2012-10-17",
          Statement: derived_iam_statements
        }
      }]

      @properties[:ManagedPolicyArns] ||= @managed_policy_arns || default_managed_policy_arns

      resource = {
        IamRole: {
          Type: "AWS::IAM::Role",
          Properties: @properties
        }
      }
      auto_camelize(resource)
    end

  private
    Registry = KubesAws::Dsl::IamRole::Registry
    def evaluate_definitions
      @iam_statements = Registry.iam_statements if Registry.iam_statements
      @managed_policy_arns = Registry.managed_policy_arns if Registry.managed_policy_arns
    end

    # In case of future use, we can set the default properties here. Originally taken from cody dsl
    def default_properties
      {}
    end

    def derived_iam_statements
      @iam_statements || default_iam_statements
    end

    def default_iam_statements
      []
      # [{
      #   Action: [
      #     "logs:CreateLogGroup",
      #     "logs:CreateLogStream",
      #     "logs:PutLogEvents",
      #     "ssm:DescribeDocumentParameters",
      #     "ssm:DescribeParameters",
      #     "ssm:GetParameter*",
      #   ],
      #   Effect: "Allow",
      #   Resource: "*"
      # }]
    end

    def default_managed_policy_arns
      # Useful when using with CodePipeline
      ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
    end
  end
end
