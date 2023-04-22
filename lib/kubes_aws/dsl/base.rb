module KubesAws::Dsl
  class Base < Kubes::CLI::Base
    include Evaluate
    include Variables

    attr_reader :options, :project_name, :full_project_name, :type
    attr_reader :resource # iam_role.resource, security_group.resource
    def initialize(options={})
      super
      @type = options[:type]
      @properties = default_properties # defaults make project.rb simpler
    end

    # In v1.0.0 defaults to not auto-camelize
    def auto_camelize(data)
      if KubesAws.config.auto_camelize
        CfnCamelizer.transform(data)
      else
        data.deep_stringify_keys!
      end
    end

    def aws
      AwsData.new
    end
    memoize :aws
  end
end
