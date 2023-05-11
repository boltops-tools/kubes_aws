require 'ostruct'

class KubesAws::Helpers::SSM
  class Fetcher
    include KubesAws::Logging
    include KubesAws::Services

    def get(name, options={})
      parameter = get_parameter(name)
      value = parameter.value
      value = Base64.strict_encode64(value).strip if base64?(options)
      value
    end
    alias_method :fetch, :get # backwards compatibility

    def list(prefix=:convention, options={})
      if prefix == :convention
        prefix = [Kubes.app, Kubes.env].compact.join('/')
      end
      # Auto add leading slash if missing
      unless prefix.starts_with?('/')
        prefix = '/' + prefix
      end

      next_token, parameters = true, []
      while next_token
        opts = {
          path: prefix,
          with_decryption: true,
        }
        opts[:next_token] = next_token unless next_token == true || next_token.nil?
        resp = ssm.get_parameters_by_path(opts)
        next_token = resp.next_token
        parameters += resp.parameters
      end
      parameters.sort_by! { |p| p.name }
      parameters.map do |parameter|
        base64_value = Base64.strict_encode64(parameter.value).strip
        base64 = options[:base64] || false # new method so dont need to deprecate with base64: nil
        value = base64?(options.merge(type: parameter.type, base64: base64)) ? base64_value : parameter.value
        env_name = parameter.name.sub("#{prefix}/",'')
        OpenStruct.new(
          name: parameter.name, # IE: /app/dev/DB_PASSWORD
          value: value,
          env_name: env_name,   # IE: DB_PASSWORD
          base64_value: base64_value,
      )
      end
    end

    def base64?(options={})
      if options[:base64].nil?
        base64 = KubesAws.config.ssm.base64
        if base64.nil?
          puts deprecation_message
          options[:type] == "SecureString" # keep legacy behavior for some time
        else
          base64
        end
      else
        options[:base64]
      end
    end

    def get_parameter(name)
      # Auto add leading slash if missing
      name = '/' + name unless name.starts_with?('/')
      resp = ssm.get_parameter(name: name, with_decryption: true)
      resp.parameter
    rescue Aws::SSM::Errors::ParameterNotFound => e
      logger.info "WARN: name #{name} not found".color(:yellow)
      logger.info e.message
      "NOT FOUND #{name}" # simple string so Kubernetes YAML is valid
    end

    def deprecation_message
      call_line = caller.find {|l| l.include?('.kubes') }
      DslEvaluator.print_code(call_line)
      puts <<~EOL.color(:yellow)
        DEPRECATION WARNING: KubesAws.config.ssm.base64 is nil.

        To turn off this warning, please explicitly set it to true or false in

        .kubes/config.rb.

            # Note: The use of KubesAws.configure instead of Kubes.configure
            KubesAws.configure do |config|
              # legacy behavior was based on the parameter type
              config.ssm.base64 = true
            end

        Or to upgrade for the future, set it to false

        .kubes/config.rb

            # Note: The use of KubesAws.configure instead of Kubes.configure
            KubesAws.configure do |config|
              # prepare for future default
              config.ssm.base64 = false
            end

        And explicitly set `base64: true` in aws_secret options.

        Example:

            aws_secret('name', base64: true)
            aws_secret('name', base64: false) # will be future default

        Future kubes_aws major versions will default KubesAws.config.ssm.base64 = false.
      EOL
    end
  end
end
