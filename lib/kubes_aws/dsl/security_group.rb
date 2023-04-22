module KubesAws::Dsl
  module SecurityGroup
    extend Memoist

    PROPERTIES = %w[
      GroupName
      GroupDescription
      SecurityGroupEgress
      SecurityGroupIngress
      Tags
      VpcId
    ]
    PROPERTIES.each do |prop|
      define_method(prop.underscore) do |v|
        @properties[prop.to_sym] = v
      end
    end
  end
end
