module KubesAws
  module Helpers
    # extend Memoist # still need in the individual modules
    include Services

    include Ecr
    include Efs
    include Secrets
    include SSM
  end
end
