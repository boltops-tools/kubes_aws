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
      iam_role_resource = IamRole.new(@options).build
      @template["Resources"].merge!(iam_role_resource)

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
