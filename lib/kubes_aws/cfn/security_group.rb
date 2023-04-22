class KubesAws::Cfn
  class SecurityGroup < KubesAws::Dsl::Base
    include KubesAws::Dsl::SecurityGroup

    def initialize(options={})
      super
      @role_path = lookup_kubes_file("security_group.rb")
      @iam_policy = {}
    end

    def build
      load_variables
      evaluate_file(@role_path) if @role_path # registers definitions to registry

      @properties[:Tags] ||= default_tags

      @resource = {
        SecurityGroup: {
          Type: "AWS::EC2::SecurityGroup",
          Properties: @properties
        }
      }
      auto_camelize(@resource) # camelize keys
    end

    def filled?
      true
    end

    def output
      text = <<~YAML
        SecurityGroupId:
          Value:
            Fn::GetAtt:
              SecurityGroup.GroupId
      YAML
      YAML.load(text)
    end

    def default_properties
      {
        GroupDescription: conventional_name, # required
        GroupName: conventional_name, # optional but set so name shows in EC2 console
      }
    end

    def default_tags
      [{ Key: "Name", Value: conventional_name}]
    end

    def conventional_name
      ["kubes", Kubes.app, Kubes.env, Kubes.extra].compact.join("-")
    end
  end
end
