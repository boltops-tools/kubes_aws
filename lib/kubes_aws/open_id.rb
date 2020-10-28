require "aws-sdk-iam"
require "aws_data"
require "openssl"

module KubesAws
  class OpenId
    extend Memoist
    include AwsServices
    include Logging

    def initialize(cluster)
      @cluster = cluster
    end

    # Method is idempotent
    def create_provider
      fingerprint = OpenSSL::Digest::SHA1.new(cert.to_der).to_s
      iam.create_open_id_connect_provider(
        url: issuer_url,
        thumbprint_list: [fingerprint],
        client_id_list: ["sts.amazonaws.com"]
      )
    rescue Aws::IAM::Errors::EntityAlreadyExists => e
      logger.debug "#{e.class}: #{e.message}"
      logger.debug "Open ID Provider already exists"
    end

    def issuer_url
      resp = eks.describe_cluster(name: @cluster)
      resp.cluster.identity.oidc.issuer
    end
    memoize :issuer_url

    # https://stackoverflow.com/questions/34601260/using-ruby-openssl-to-download-and-read-certificates
    def cert
      uri = URI(issuer_url)
      ctx = OpenSSL::SSL::SSLContext.new
      sock = TCPSocket.new(uri.host, 443)
      ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
      ssl.connect
      ssl.peer_cert_chain.last
    end
    memoize :cert

    def aws_region
      AwsData.new.region
    end
  end
end
