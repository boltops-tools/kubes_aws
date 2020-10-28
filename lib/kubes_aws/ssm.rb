require "aws-sdk-ssm"

module KubesAws
  class SSM
    include AwsServices

    def initialize(upcase: false, base64: false, prefix: nil, filters: [])
      @upcase, @base64, @filters = upcase, base64, filters
      @prefix = ENV['AWS_SSM_PREFIX'] || prefix # IE: prefix: /demo/dev/
    end

    def call
      items.each do |item|
        next unless item.name.include?(@prefix)

        resp = ssm.get_parameter(name: item.name, with_decryption: true)
        parameter = resp.parameter

        key = parameter.name.sub(@prefix,'')
        value = parameter.value
        value = Base64.strict_encode64(value).strip if @base64

        key = key.upcase if @upcase
        self.class.data[key] = value
      end
    end

    # Returns flattened lazy Enumerator
    def items
      Enumerator.new do |y|
        next_token = nil
        loop do
          args = {max_results: PAGE_SIZE}
          args[:next_token] = next_token if next_token
          args.merge!(parameter_filters: @filters)

          resp = ssm.get_parameters_by_path(
            path: @prefix,
          )

          items = resp.parameters
          next_token = resp.next_token

          y.yield(items, resp) # also provided the original resp always in case it is useful
          break unless next_token
        end
      end.lazy.flat_map { |v| v }
    end

    PAGE_SIZE = 1

    def data
      self.class.data
    end

    class_attribute :data
    self.data = {}
  end
end
