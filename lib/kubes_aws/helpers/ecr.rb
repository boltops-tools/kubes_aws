module KubesAws::Helpers
  module Ecr
    def aws_ecr_repo(name)
      repository = aws_ecr_repository(name)
      repository.repository_uri if repository
    end

    def aws_ecr_repository(name)
      resp = ecr.describe_repositories(repository_names: [name])
      resp.repositories.first
    rescue Aws::ECR::Errors::RepositoryNotFoundException => e
      logger.info "ERROR: #{e.class} #{e.message}".color(:red)
      exit 1 # this already shows the call line
    end
  end
end
