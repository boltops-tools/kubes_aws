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
  end
end
