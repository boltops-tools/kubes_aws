require "kubes_aws/version"
require "logger"

require "kubes_aws/autoloader"
KubesAws::Autoloader.setup

module KubesAws
  class Error < StandardError; end

  @@logger = nil
  def logger
    @@logger ||= Kubes.logger
  end

  def logger=(v)
    @@logger = v
  end

  # Friendlier method configure.
  #
  #    .kubes/config/env/dev.rb
  #    .kubes/config/plugins/google.rb # also works
  #
  # Example:
  #
  #     KubesGoogle.configure do |config|
  #       config.hooks.gke_whitelist = true
  #     end
  #
  def configure(&block)
    Config.instance.configure(&block)
  end

  def config
    Config.instance.config
  end

  # KubesAws.managed_iam_role
  # Kubes manages with .kubes/aws/iam_role.rb
  def managed_iam_role
    cfn = KubesAws::Cfn.new
    unless cfn.exist?
      logger.debug "WARN: KubesAws.managed_iam_role: stack does not exist."
      logger.debug "Maybe you need to run kubes aws deploy?"
      return
    end
    stack = cfn.show
    output = stack.outputs.find { |o| o.output_key == "IamRoleArn" }
    output.output_value if output
  end
  alias_method :managed_iam_role_arn, :managed_iam_role

  extend self
end

Kubes::Plugin.register(KubesAws)
