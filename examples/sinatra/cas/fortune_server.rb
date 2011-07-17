require 'sinatra'
require 'json'

##
# This server is half of a very rough, ad-hoc client-server implementation of
# the fortune program.  It is a demonstration of
#
# 1. CAS proxying as implemented by aker, and
# 2. How ridiculously complex we can make simple UNIX programs[0].
#
# [0] http://radar.oreilly.com/2007/03/sfearthquakes-on-twitter.html
class FortuneServer < Sinatra::Base
  ##
  # A list of fortunes.
  #
  # @return [Array<String>]
  attr_accessor :fortunes

  ##
  # Instantiates a server, loading up an initial fortune list in the process.
  # This is really only called by Rack.
  #
  # @param args Construction arguments; used by Rack.
  def initialize(*args)
    super

    self.fortunes = JSON.parse(File.read(File.join(File.dirname(__FILE__), 'fortunes.json')))
  end

  ##
  # Make all actions require authentication.
  before do
    env['aker.check'].authentication_required!
  end

  ##
  # `#index`.
  #
  # Returns HTTP 200 with a JSON array of the form
  #
  #     [ { "id": (number), "fortune": (string) }, ... ]
  #
  # .
  get '/fortunes' do
    content_type 'application/json'

    fortunes.inject([0, []]) do |(i, a), f|
      [i + 1, a << [i, f]]
    end.last.map do |i, f|
      { 'id' => i, 'fortune' => f }
    end.to_json
  end

  ##
  # `#show`.
  #
  # If the resource exists, returns HTTP 200 with
  #
  #     { "id": (id), "fortune": (requested fortune as a string) }
  #
  # .  Otherwise, returns an empty response body with HTTP 404.
  get '/fortunes/:id' do
    content_type 'application/json'

    if fortunes[requested_id]
      { 'id' => requested_id, 'fortune' => fortunes[requested_id] }.to_json
    else
      status 404
    end
  end

  ##
  # `#create`.
  #
  # Expects the following JSON format:
  #
  #     { "fortune": (string) }
  #
  # If successful, returns HTTP 200 with
  #
  #     { "ok": true }
  #
  # .  Otherwise, returns HTTP 500 with an undefined body.
  post '/fortunes' do
    fortunes << posted_fortune

    headers 'Location' => "/fortunes/#{fortunes.length - 1}"
    ok
  end

  ##
  # `#update`.
  #
  # Expects the following JSON format:
  #
  #     { "fortune": (string) }
  #
  # If the resource exists and successful, returns HTTP 200 with
  #
  #     { "ok": true }
  #
  # .
  #
  # If the resource does not exist, returns HTTP 404 with an empty response
  # body.
  # Otherwise, returns HTTP 500 with an undefined body.
  put '/fortunes/:id' do
    if fortunes[requested_id]
      fortunes[requested_id] = posted_fortune
      ok
    else
      status 404
    end
  end

  ##
  # `#destroy`.
  #
  # If the resource exists, returns HTTP 200 with
  #
  #     { "ok": true }
  #
  # .  Otherwise, returns HTTP 404 with an empty response body.
  delete '/fortunes/:id' do
    fortunes.slice!(requested_id) ? ok : status(404)
  end

  private

  ##
  # Integer representation of the `:id` parameter.
  #
  # @return [Integer]
  def requested_id
    params[:id].to_i
  end

  ##
  # Reads a fortune object from the Rack input stream.
  def posted_fortune
    JSON.parse(request.env['rack.input'].read)['fortune']
  end

  ##
  # Convenience method for generating a canonical "ok" response.
  #
  # @return [String] `{ "ok": true }`
  def ok
    content_type 'application/json'
    status 200
    { 'ok' => true }.to_json
  end
end
