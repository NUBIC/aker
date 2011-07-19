require 'aker'

module Aker::Rack
  ##
  # Methods used by Rack middleware for reading configuration data out of the
  # Rack environment.
  module ConfigurationHelper
    include EnvironmentHelper

    def login_path(env)
      configuration(env).parameters_for(:rack)[:login_path]
    end

    def logout_path(env)
      configuration(env).parameters_for(:rack)[:logout_path]
    end
  end
end
