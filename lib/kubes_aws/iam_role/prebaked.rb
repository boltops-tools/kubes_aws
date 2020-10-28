class KubesAws::IamRole
  module Prebaked
    def prebaked_policies
      {
        secrets_read_only: secrets_read_only
      }
    end

    def secrets_read_only
      {
        policy_document: {
          Version: "2012-10-17",
          Statement: {
            Effect: "Allow",
            Action: [
              "secretsmanager:Describe*",
              "secretsmanager:Get*",
              "secretsmanager:List*"
            ],
            Resource: "*"
          }
        },
        policy_name: "SecretsReadOnly",
      }
    end
  end
end