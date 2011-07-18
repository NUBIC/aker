require 'bundler'
Bundler.setup

require 'sinatra'
require 'json'
require 'haml'
require 'aker'

##
# This client is half of a very rough, ad-hoc client-server implementation of
# the fortune program.  It is a demonstration of
#
# 1. CAS proxying as implemented by aker, and
# 2. How ridiculously complex we can make simple UNIX programs[0].
#
# [0] http://radar.oreilly.com/2007/03/sfearthquakes-on-twitter.html

##
# First, we set up aker.
#
# Instead of the customary
#
#     Aker::Rack.use_in(self)
#
# we instead use
#
#     Aker::Rack.use_in(Sinatra::Application)
#
# because self is `main` extended with private delegators to
# `Sinatra::Application`, one of which is `use`.  `use` on Sinatra::Application
# is not private, however, so we kludge things up a bit in the name of keeping
# the client in a single file.
Aker.configure do
  cas_parameters :base_url => ENV['CAS_BASE'],
                 :proxy_retrieval_url => "#{ENV['CAS_CALLBACK']}/retrieve_pgt",
                 :proxy_callback_url => "#{ENV['CAS_CALLBACK']}/receive_pgt"

  ui_mode :cas
  authority :cas
end

#
# The CAS server we use in this example runs without SSL, so configure
# Castanet to allow that.
#
require File.expand_path("../permit_insecure_cas.rb", __FILE__)

use Rack::Session::Cookie

Aker::Rack.use_in(Sinatra::Application)

##
# Next, an administrative detail.
#
# To keep maintenance (monetary) costs down, we use self-signed SSL
# certificates to talk to the CAS proxy callback.  (The CAS protocol requires
# it.)  As this would normally result in certificate verification failures, we
# step around the issue by disabling certificate verification.
#
# A better way would be to add the certificate to a trusted certificate store a
# la JKS, but there is no such thing in Ruby.
OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:verify_mode] = OpenSSL::SSL::VERIFY_NONE

##
# Require authentication for all actions.
before do
  @user = env['aker'].user

  env['aker'].authentication_required!
end

##
# Configure the Fortune model.
require File.join(File.dirname(__FILE__), 'fortune')

Fortune.base_uri = 'http://localhost:9696/fortunes'
Fortune.service_uri = 'http://localhost:9696'

##
# Alias for /fortunes.
get '/' do
  redirect '/fortunes'
end

##
# `#index`.
get '/fortunes' do
  @fortunes = Fortune.all(@user)

  haml :index
end

##
# `#new`.
get '/fortunes/new' do
  haml :new
end

##
# `#create`.
post '/fortunes' do
  Fortune.create(params['fortune'], @user)

  redirect '/fortunes'
end

##
# `#edit`.
get '/fortunes/:id/edit' do
  @fortune = Fortune.find(params[:id], @user)

  haml :edit
end

##
# `#update`.
post '/fortunes/:id/update' do
  @fortune = Fortune.find(params[:id], @user)

  @fortune.update(params['fortune'], @user)

  redirect '/fortunes'
end

##
# `#delete`.
#
# Yes, this is a GET with side-effects.
# No, it's not safe.
# Yes, this makes it easier to write HTML to drive deletion.
get '/fortunes/:id/delete' do
  Fortune.destroy(params[:id], @user)

  @fortunes = Fortune.all(@user)

  redirect '/fortunes'
end

get '/pt' do
  pt = @user.cas_proxy_ticket(Fortune.service_uri)

  "Got proxy ticket #{pt}, but not going to use it."
end
