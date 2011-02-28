#\ -p 9696

require 'bundler'
Bundler.setup

#
# This rackup file provides bcsec and Rack configuration for the fortune
# server.
#
# First, we load bcsec and the server code.
#
require 'bcsec'
require File.join(File.dirname(__FILE__), 'fortune_server')

#
# The CAS server we use in this example runs without SSL, so configure
# Castanet to allow that.
#
require File.expand_path("../permit_insecure_cas.rb", __FILE__)

#
# Next, we configure Bcsec, set up session middleware (which bcsec uses to
# store user data), and then insert bcsec's Rack middleware into the Rack
# middleware stack.  Session middleware must be inserted before bcsec's
# middleware.
#
# N.B.  This configuration technically permits UI logins via `/login`, as bcsec
# provides a login form by default.  However, because we are not using any
# authorities that understand username/password pairs, form login will always
# fail.
#
Bcsec.configure do
  authority :cas
  cas_parameters :base_url => 'http://localhost:9697'
  api_modes :cas_proxy
end

use Rack::Session::Cookie

Bcsec::Rack.use_in(self)

#
# Finally, we start the server.
#
run FortuneServer
