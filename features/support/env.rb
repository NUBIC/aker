require File.expand_path("../../../vendor/gems/environment", __FILE__)

require "spec"
require "fileutils"

$LOAD_PATH.unshift File.expand_path("../../../lib", __FILE__)

require 'bcsec'

require 'capybara'
require 'capybara/cucumber'
require 'rack/test'

require File.expand_path("../controllable_cas_server.rb", __FILE__)

Before('@cas') do
  Capybara.current_driver = :culerity
  start_cas_server
end

After('@cas') do
  stop_cas_server
  Capybara.use_default_driver
end

module Bcsec::Cucumber
  class World
    include Rack::Test::Methods
    include Spec::Matchers
    include FileUtils

    CAS_PORT = 5409

    def app
      @app or fail "No rack app created yet"
    end

    def tmpdir
      @tmpdir ||= "/tmp/bcsec-integrated-tests"
      unless File.exist?(@tmpdir)
        mkdir_p @tmpdir
        puts "Using tmpdir #{@tmpdir}"
      end
      @tmpdir
    end

    def start_cas_server
      @cas_server = ControllableCasServer.new(tmpdir, CAS_PORT)
      @cas_server.start
    end

    def stop_cas_server
      @cas_server.stop
    end
  end
end

World do
  Bcsec::Cucumber::World.new
end
