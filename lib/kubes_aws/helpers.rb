module KubesAws
  module Helpers
    extend Memoist
    include Services

    def aws_secret(name, options={})
      fetcher = Secrets::Fetcher.new
      fetcher.get(name, options)
    end

    def aws_secrets(options={})
      options[:prefix] ||= :convention
      fetcher = Secrets::Fetcher.new
      fetcher.list(options[:prefix], options)
    end

    def aws_ssm(name, options={})
      fetcher = SSM::Fetcher.new
      fetcher.get(name, options)
    end
    alias_method :aws_ssm_parameter, :aws_ssm

    def aws_ssm_parameters(options={})
      options[:prefix] ||= :convention
      fetcher = SSM::Fetcher.new
      fetcher.list(options[:prefix], options)
    end

    def aws_secret_data(name, options={})
      generic_secret_data(:aws_secret, name, options)
    end
  end
end
