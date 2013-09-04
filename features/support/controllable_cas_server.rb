require File.expand_path('../controllable_rack_server', __FILE__)
require File.expand_path('../ssl_env', __FILE__)

module Aker
  module Cucumber
    class ControllableCasServer < ControllableRackServer
      include FileUtils

      attr_reader :users_database_filename

      def initialize(tmpdir, port)
        super(:port => port, :tmpdir => tmpdir, :ssl => true, :app => TestCasServer)
      end

      def register_user(username, password)
        post! URI.parse("#{base_url}/_accept") do |req|
          req.set_form_data('username' => username, 'password' => password)
        end
      end

      def reset
        post! URI.parse("#{base_url}/_reset")
      end

      protected

      def post!(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = ssl?
        http.cert = ssl_env.certificate

        req = Net::HTTP::Post.new(uri.path)
        yield req if block_given?

        resp = http.request(req)
        raise "Expected 2xx from POST #{uri}, got #{resp.code}" unless Net::HTTPSuccess === resp
      end

      def log_filename
        "cas-out.log"
      end
    end
  end
end
