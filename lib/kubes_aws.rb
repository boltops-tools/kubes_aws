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

  extend self
end
