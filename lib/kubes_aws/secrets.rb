require "aws-sdk-secretsmanager"

module KubesAws
  class Secrets
    include AwsServices

    def initialize(upcase: false, base64: false, prefix: nil, filters: [])
      @upcase, @base64, @filters = upcase, base64, filters
      @prefix = ENV['AWS_SECRET_PREFIX'] || prefix # IE: prefix: demo/dev/
    end

    def call
      items.each do |item|
        next unless item.name.include?(@prefix) if @prefix

        secret_value = secrets.get_secret_value(secret_id: item.name)
        value = secret_value.secret_string
        value = Base64.strict_encode64(value).strip if @base64

        key = item.name
        key = key.sub(@prefix,'') if @prefix
        key = key.upcase if @upcase
        self.class.data[key] = value
      end
    end

    # Returns flattened lazy Enumerator
    def items
      Enumerator.new do |y|
        next_token = nil
        loop do
          args = {max_results: PAGE_SIZE, sort_order: "asc"}
          args[:next_token] = next_token if next_token
          args.merge!(filters: @filters)

          resp = secrets.list_secrets(args)

          items = resp.secret_list
          next_token = resp.next_token

          y.yield(items, resp) # also provided the original resp always in case it is useful
          break unless next_token
        end
      end.lazy.flat_map { |v| v }
    end

    PAGE_SIZE = 20

    def data
      self.class.data
    end

    class_attribute :data
    self.data = {}
  end
end
