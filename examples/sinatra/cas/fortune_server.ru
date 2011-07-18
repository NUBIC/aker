#\ -p 9696

require 'bundler'
Bundler.setup

#
# This rackup file provides aker and Rack configuration for the fortune
# server.
#
# First, we load aker and the server code.
#
require 'aker'
require File.join(File.dirname(__FILE__), 'fortune_server')

#
# The CAS server we use in this example runs without SSL, so configure
# Castanet to allow that.
#
require File.expand_path("../permit_insecure_cas.rb", __FILE__)

#
# Next, we configure Aker, set up session middleware (which aker uses to
# store user data), and then insert aker's Rack middleware into the Rack
# middleware stack.  Session middleware must be inserted before aker's
# middleware.
#
# N.B.  This configuration technically permits UI logins via `/login`, as aker
# provides a login form by default.  However, because we are not using any
# authorities that understand username/password pairs, form login will always
# fail.
#
Aker.configure do
  authority :cas
  cas_parameters :base_url => ENV['CAS_BASE']
  api_modes :cas_proxy
end

use Rack::Session::Cookie

Aker::Rack.use_in(self)

#
# Finally, we start the server.
#
run FortuneServer
