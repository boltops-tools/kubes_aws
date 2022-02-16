module KubesAws
  module Helpers
    extend Memoist
    include Services

    def aws_secret(name, options={})
      fetcher = Secrets::Fetcher.new(options)
      fetcher.fetch(name)
    end

    def aws_ssm(name, options={})
      fetcher = SSM::Fetcher.new(options)
      fetcher.fetch(name)
    end

    def aws_secret_data(name, options={})
      generic_secret_data(:aws_secret, name, options)
    end
  end
end
