require File.expand_path("../../../vendor/gems/environment", __FILE__)

require "spec"

$LOAD_PATH.unshift File.expand_path("../../../lib", __FILE__)

require 'bcsec'

require 'capybara'
require 'capybara/cucumber'
require 'rack/test'

module Bcsec::Cucumber
  class World
    include Rack::Test::Methods
    include Spec::Matchers

    def app
      @app or fail "No rack app created yet"
    end
  end
end

World do
  Bcsec::Cucumber::World.new
end
