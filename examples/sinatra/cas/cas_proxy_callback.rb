require 'bundler'
Bundler.setup

#
# A CAS proxy callback is a webapps used by CAS servers and CAS clients.  A CAS
# server deposits a proxy ticket in a proxy callback; a CAS client retrieves the
# ticket from said callback.
#
# The proxy callback can be composed with another application, but for Ruby
# webapps that can't be done unless your webapp can respond to multiple
# simultaneous requests, i.e. is running with multiple workers.  Most
# development environments for Ruby webapps don't do this -- WEBrick certainly
# doesn't make it easy -- so we don't do it either.
#
# (Unicorn makes it really easy, but Unicorn doesn't do HTTPS.)
#
# Anyway.  We'll be using bcsec's CAS proxy callback, so we need to load up
# bcsec.
#
require 'bcsec'

#
# We're also going to need Rack.
#
require 'rack'

#
# The CAS proxy callback must be accessed over HTTPS, so we need to start an
# HTTPS server.
#
require 'webrick'
require 'webrick/https'

certificate_file = File.join(File.dirname(__FILE__), 'cas_proxy_callback.crt')
private_key_file = File.join(File.dirname(__FILE__), 'cas_proxy_callback.key')

#
# The CAS proxy callback uses a Ruby pstore to hold proxy tickets.
#
pstore_path = File.join(File.dirname(__FILE__), %w(var cas_proxy_callback.pstore))

#
# Now we start the callback.
#
conf = {
  :app => Bcsec::Cas::RackProxyCallback.application(:store => pstore_path),
  :server => 'webrick',
  :Port => 9698,
  :SSLEnable => true,
  :SSLVerifyClient => OpenSSL::SSL::VERIFY_NONE,
  :SSLCertificate => OpenSSL::X509::Certificate.new(File.read(certificate_file)),
  :SSLPrivateKey => OpenSSL::PKey::RSA.new(File.read(private_key_file)),
  :SSLCertName => [ [ 'CN', WEBrick::Utils::getservername ] ],
  :Logger => WEBrick::Log::new($stderr, WEBrick::Log::DEBUG)
}

server = Rack::Server.new(conf)

# A hack to set the Rack app until c73b474525bace3f059a130b15413abd4d917086 @
# http://github.com/rack/rack.git is released.  Rack::Server's documentation
# states that passing :app as a constructor option should work, but prior to
# c73b474, it didn't.
server.instance_variable_set(:@app, conf[:app])

server.start
