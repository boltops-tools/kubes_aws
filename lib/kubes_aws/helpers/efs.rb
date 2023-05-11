module KubesAws::Helpers
  module Efs
    extend Memoist

    def aws_efs(name)
      resp = efs.describe_file_systems
      found = resp.file_systems.find do |fs|
        fs.tags.find { |t| t.key == "Name" && t.value == name }
      end
      found[:file_system_id] if found

      # TODO: use lazy enumerator and pagination
      # "test"
    end
    memoize :aws_efs
  end
end
