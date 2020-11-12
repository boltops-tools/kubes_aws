module KubesAws
  class Config
    include Singleton

    def defaults
      c = ActiveSupport::OrderedOptions.new
      c.secrets = ActiveSupport::OrderedOptions.new
      c.secrets.base64 = true
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
