class KubesAws::Secrets
  class Fetcher
    include KubesAws::Logging
    include KubesAws::Services

    def get(secret_id, options={})
      value = get_secret_value(secret_id, options)
      return unless value

      value = JSON.load(value)[options[:json_key]] if options[:json_key]
      value = Base64.strict_encode64(value).strip if base64?(options)
      value
    end

    def list(prefix=:convention, options={})
      if prefix == :convention
        prefix = [Kubes.app, Kubes.env].compact.join('/')
      end

      next_token, secrets = true, []
      while next_token
        opts = {
          include_planned_deletion: false,
          filters: [key: "name", values: [prefix]],
        }
        opts[:next_token] = next_token unless next_token == true || next_token.nil?
        resp = secretsmanager.list_secrets(opts)
        next_token = resp.next_token
        secrets += resp.secret_list
      end

      secrets.sort_by! { |s| s.name }
      secrets.map do |secret|
        value = get_secret_value(secret.name, options)
        base64_value = Base64.strict_encode64(value).strip
        env_name = secret.name.sub("#{prefix}/",'')
        OpenStruct.new(
          name: secret.name,
          value: value,
          env_name: env_name,
          base64_value: base64_value,
        )
      end
    end

    def base64?(options={})
      if options[:base64].nil?
        base64 = KubesAws.config.secrets.base64
        if base64.nil?
          puts deprecation_message
          true # keep legacy behavior for some time
        else
          base64
        end
      else
        options[:base64]
      end
    end

    def get_secret_value(secret_id, options={})
      opts = options.slice(:version_id, :version_stage) # so don't pass in :base64
      opts[:secret_id] = secret_id
      secret_value = secretsmanager.get_secret_value(opts)
      secret_value.secret_string
    rescue Aws::SecretsManager::Errors::ResourceNotFoundException => e
      logger.info "WARN: secret_id #{secret_id} not found".color(:yellow)
      logger.info e.message
      # Legacy behavior, return a string so Kubernetes YAML is valid
      # "NOT FOUND #{secret_id}" # simple string so Kubernetes YAML is valid
      nil # new behavior, return nil so Kubernetes YAML is valid
    end

    def deprecation_message
      call_line = caller.find {|l| l.include?('.kubes') }
      DslEvaluator.print_code(call_line)
      puts <<~EOL.color(:yellow)
        DEPRECATION WARNING: KubesAws.config.secrets.base64 is nil.

        To turn off this warning, please explicitly set it to true or false in

        .kubes/config.rb.

            # Note: The use of KubesAws.configure instead of Kubes.configure
            KubesAws.configure do |config|
              # true to keep legacy behavior, false for future default
              config.secrets.base64 = true
            end

        Or to upgrade for the future, set it to false

        .kubes/config.rb

            # Note: The use of KubesAws.configure instead of Kubes.configure
            KubesAws.configure do |config|
              # prepare for future default
              config.secrets.base64 = false
            end

        And explicitly set `base64: true` in aws_secret options.

        Example:

            aws_secret('name', base64: true)  # will be legacy behavior
            aws_secret('name', base64: false) # will be future default

        Future kubes_aws major versions will default KubesAws.config.secrets.base64 = false.
      EOL
    end
  end
end
