class KubesAws::Cfn
  class Builder < Kubes::CLI::Base
    def initialize(options={})
      super
      @full_project_name = [Kubes.app, Kubes.env, Kubes.extra].compact.join("-")
      @template = {
        "Description" => "Kubes AWS Resources: #{@full_project_name}",
        "Resources" => {}
      }
    end

    def template
      iam_role = IamRole.new(@options)
      iam_role.build
      if iam_role.filled?
        @template["Resources"].merge!(iam_role.resource)
        @template["Outputs"] ||= {}
        @template["Outputs"].merge!(iam_role.output)
      end

      security_group = SecurityGroup.new(@options)
      security_group.build
      if security_group.filled?
        @template["Resources"].merge!(security_group.resource)
        @template["Outputs"] ||= {}
        @template["Outputs"].merge!(security_group.output)
      end

      write
      @template
    end
    alias_method :run, :template

    def write
      template_path = ".kubes/tmp/cfn-template.yml"
      FileUtils.mkdir_p(File.dirname(template_path))
      IO.write(template_path, YAML.dump(@template))
      logger.info "Template built: #{pretty_path(template_path)}"
    end
  end
end
