#\ -p 9697
require 'bundler'
Bundler.setup

#
# We start off by loading up bcsec.
#
require 'bcsec'

#
# Next, some housekeeping.
#
# The CAS proxy callback must be accessed over HTTPS.  We cut out SSL
# certificate verification because it's not important to this example, and
# Ruby's OpenSSL interfaces does not expose a cleaner way of setting up
# certificate trust.  (It'd be a lot better if we had something like a Java key
# store, but we don't.)
#

require 'openssl/ssl'
OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:verify_mode] = OpenSSL::SSL::VERIFY_NONE

#
# Now we finally get to something that actually involves bcsec -- namely,
# configuring bcsec's authorities.
#
# Since RubyCAS-Server uses bcsec only as an authenticator, we do not need
# to set up any of bcsec's Rack extensions.
#

credentials = {
 'mr296' => 'br0wn'
}

Bcsec.configure do
  static = Bcsec::Authorities::Static.new

  credentials.each do |username, password|
    static.valid_credentials!(:user, username, password)
  end

  authority static
end

#
# RubyCAS-Server implements authentication strategies with what it calls
# authenticators.  The following code builds an authenticator that instructs
# bcsec to validate username/password pairs.
#

require 'casserver/authenticators/base'

class BcsecAuthenticator < CASServer::Authenticators::Base
  def validate(credentials)
    Bcsec.authority.valid_credentials?(:user, credentials[:username], credentials[:password])
  end
end

#
# We have finished declaring the components on which RubyCAS-Server depends, so
# now it's time to tie them all together.
#
# Picnic expects to find a Picnic::Conf object in $CONF, so here we give it what
# it wants.  Here, we instruct RubyCAS-Server to use BcsecAuthenticator and
# give it a database for storing state.
#
# N.B. In-memory SQLite3 databases will not work with RubyCAS-Server: the schema
# will be lost between its instantiation and the first request.
#
# We manually load Picnic because we're going to be building a
# Picnic::Conf object in this rackup file instead of having Picnic read a
# configuration file.  (Doing it this way reduces the number of files you have
# to read through.)
#

require 'picnic'
require 'picnic/conf'

$CONF = Picnic::Conf.new({
  :authenticator => [
    { :class => 'BcsecAuthenticator' }
  ],
  :database => {
    :adapter => 'sqlite3',
    :database => File.join(File.dirname(__FILE__), %w(var casserver.sqlite3))
  }
})

# Now we can instantiate RubyCAS-Server and instruct Rack how to run
# RubyCAS-Server.
#
# Requiring casserver loads server configuration, so this require has to
# come after $CONF is set.
require 'casserver'
CASServer.create

#
# We use the Rack::Static middleware to point requests for resources in
# /themes/* to RubyCAS-Server's /public/themes directory, which is inside the
# RubyCAS-Server gem.
#

asset_path = File.join(File.dirname(Gem.find_files('casserver').first), %w(.. public))
use Rack::Static, :urls => ['/themes'], :root => asset_path

#
# Finally, we tell Rack to run RubyCAS-Server.
#

run CASServer
