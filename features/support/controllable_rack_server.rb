require File.expand_path('../spawned_http_server.rb', __FILE__)

module Aker::Cucumber
  class ControllableRackServer < SpawnedHttpServer
    attr_reader :ssl_env
    attr_accessor :app

    def initialize(options={})
      super(options)
      @app_creator = options.delete(:app_creator)
      @app = options.delete(:app)
      @ssl_env = SslEnv.new if ssl?
    end

    def app
      @app ||=
        begin
          raise "Either provide an app_creator or set the app directly" unless @app_creator
          @app_creator.call
        end
    end

    def exec_server
      Signal.trap("TERM") {
        $stdout.flush
        $stderr.flush
        exit!(0)
      }

      $stdout = File.open("#{tmpdir}/#{log_filename}", "w")
      $stderr = $stdout

      options = { :Port => port }
      if ssl?
        options.merge!(ssl_env.webrick_ssl)
      end

      a = app
      linted_app = Rack::Builder.new do
        use Rack::Lint

        run a
      end

      ::Rack::Handler::WEBrick.run linted_app, options
    end

    protected

    def log_filename
      "rack-#{port}.log"
    end
  end
end
