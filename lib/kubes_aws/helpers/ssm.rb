module KubesAws::Helpers
  module SSM
    def aws_ssm(name, options={})
      fetcher = Fetcher.new
      fetcher.get(name, options)
    end
    alias_method :aws_ssm_parameter, :aws_ssm

    def aws_ssm_parameters(options={})
      options[:prefix] ||= :convention
      fetcher = Fetcher.new
      fetcher.list(options[:prefix], options)
    end
  end
end
