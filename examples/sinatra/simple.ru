require 'bundler'
Bundler.setup

require 'sinatra'
require 'simple'

Bcsec.configure do
  credentials = {
    'mr296' => 'br0wn'
  }

  static = Bcsec::Authorities::Static.new

  credentials.each do |username, password|
    static.valid_credentials!(:user, username, password)
  end

  authority static
  api_modes :http_basic
end

use Rack::Session::Cookie

Bcsec::Rack.use_in(self)

run Simple
