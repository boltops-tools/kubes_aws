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

  extend self
end

Kubes::Plugin.register(KubesAws)
