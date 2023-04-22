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
      evaluate_file(@role_path) if @role_path # registers definitions to registry
      evaluate_definitions # build definitions from registry. can set: @iam_statements and @managed_policy_arns
      @properties[:AssumeRolePolicyDocument] = trust_policy # set after evaluate_file so @cluster is set
      @properties[:Policies] = [{
        PolicyName: "KubesAwsManagedPolicy",
        PolicyDocument: {
          Version: "2012-10-17",
          Statement: derived_iam_statements
        }
      }]
      @properties.delete(:Policies) if derived_iam_statements.empty?

      @properties[:ManagedPolicyArns] ||= @managed_policy_arns || default_managed_policy_arns
      @properties.delete(:ManagedPolicyArns) if @properties[:ManagedPolicyArns].empty?

      @resource = {
        IamRole: {
          Type: "AWS::IAM::Role",
          Properties: @properties
        }
      }
      auto_camelize(resource) # camelize keys
    end
    attr_reader :resource # iam_role.resource method

    # Happens when the DSL runs but there was no .kubes/aws/iam_role.rb file
    def unfilled?
      @properties['Policies'].nil? && @properties['ManagedPolicyArns'].nil?
    end

    def filled?
      !unfilled?
    end

    def output
      # {
      #   IamRoleName: {
      #     Value: { "Fn::GetAtt": ["IamRole", "Arn"] },
      #     Description: "IAM Role Arn"
      #   }
      # }
      text = <<~YAML
        IamRole:
          Value:
            Fn::GetAtt:
              IamRole.Arn
      YAML
      YAML.load(text)
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

    # In case of future use, we can set the default properties here. Originally taken from cody dsl
    def default_iam_statements
      []
    end

    # In case of future use, we can set the default properties here. Originally taken from cody dsl
    def default_managed_policy_arns
      []
    end
  end
end
