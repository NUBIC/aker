require File.expand_path('../spawned_http_server.rb', __FILE__)

module Bcsec::Cucumber
  class ControllableRackServer < SpawnedHttpServer
    attr_accessor :app

    def initialize(options={})
      super(options)
      @app_creator = options.delete(:app_creator)
      @app = options.delete(:app)
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

      ::Rack::Handler::WEBrick.run app, :Port => port
    end

    protected

    def log_filename
      "rack-#{Process.pid}.log"
    end
  end
end
