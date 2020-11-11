class KubesAws::Secrets
  class Fetcher
    include KubesAws::Logging
    include KubesAws::Services

    def initialize(options={})
      @options = options
      @base64 = options[:base64]
    end

    def fetch(secret_id)
      value = fetch_value(secret_id)
      value = Base64.strict_encode64(value).strip if base64?
      value
    end

    def base64?
      @base64.nil? ? KubesAws.config.base64_secrets : @base64
    end

    def fetch_value(secret_id)
      secret_value = secrets.get_secret_value(secret_id: secret_id)
      secret_value.secret_string
    rescue Aws::SecretsManager::Errors::ResourceNotFoundException => e
      logger.info "WARN: secret_id #{secret_id} not found".color(:yellow)
      logger.info e.message
      "NOT FOUND #{secret_id}" # simple string so Kubernetes YAML is valid
    end
  end
end
