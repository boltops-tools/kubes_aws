module KubesAws
  class Config
    include Singleton

    def defaults
      c = ActiveSupport::OrderedOptions.new
      c.secrets = ActiveSupport::OrderedOptions.new
      c.secrets.base64 = nil # See: Secrets::Fetcher#base64? for deprecation warning
      c.ssm = ActiveSupport::OrderedOptions.new
      c.ssm.base64 = nil # See: SSM::Fetcher#base64? for deprecation warning
      c.iam = ActiveSupport::OrderedOptions.new
      c.iam.enable_create_odic = true
      c
    end

    @@config = nil
    def config
      @@config ||= defaults
    end

    def configure
      yield(config)
    end
  end
end
