module KubesAws::Helpers
  module Secrets
    def aws_secret(name, options={})
      fetcher = Fetcher.new
      fetcher.get(name, options)
    end

    def aws_secrets(options={})
      options[:prefix] ||= :convention
      fetcher = Fetcher.new
      fetcher.list(options[:prefix], options)
    end

    def aws_secret_data(name, options={})
      generic_secret_data(:aws_secret, name, options)
    end
  end
end
