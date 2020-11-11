class KubesAws::SSM
  class Fetcher
    include KubesAws::Logging
    include KubesAws::Services

    def initialize(options={})
      @options = options
      @base64 = options[:base64]
    end

    def fetch(name)
      parameter = fetch_parameter(name)
      value = parameter.value
      value = Base64.strict_encode64(value).strip if base64?(parameter.type)
      value
    end

    def base64?(type)
      if @base64.nil?
        type == "SecureString"
      else
        @base64
      end
    end

    def fetch_parameter(name)
      resp = ssm.get_parameter(name: name, with_decryption: true)
      resp.parameter
    rescue Aws::SSM::Errors::ParameterNotFound => e
      logger.info "WARN: name #{name} not found".color(:yellow)
      logger.info e.message
      "NOT FOUND #{name}" # simple string so Kubernetes YAML is valid
    end
  end
end
