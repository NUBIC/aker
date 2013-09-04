require 'net/http'
require 'rack/utils'
require 'securerandom'
require 'sinatra'
require 'yaml'

class TestCasServer < Sinatra::Base
  include Rack::Utils

  attr_reader :tickets
  attr_reader :credentials

  enable :sessions
  set :session_secret, 'supersekrit'

  class Ticket < Struct.new(:service, :nonce, :username, :proxies, :used)
    alias_method :used?, :used
  end

  def initialize(*)
    super

    @tickets = {}
    @credentials = {}

    @ticket_file = "#{Dir.pwd}/tickets.yml"
    @credentials_file = "#{Dir.pwd}/credentials.yml"

    load_state
  end

  def load_state
    if File.exists?(@ticket_file)
      tickets.update(YAML.load_file(@ticket_file))
    end

    if File.exists?(@credentials_file)
      credentials.update(YAML.load_file(@credentials_file))
    end
  end

  def save_state
    File.open(@ticket_file, 'w') { |f| f.write(tickets.to_yaml) }
    File.open(@credentials_file, 'w') { |f| f.write(credentials.to_yaml) }
  end

  def nonce(prefix = '')
    # SecureRandom.urlsafe_base64 may generate non-kosher characters like _, so
    # we restrict ourselves to hex digits
    prefix + "-" + SecureRandom.hex(64)
  end

  def gen_ticket(service, nonce, username, proxies = [])
    Ticket.new(service, nonce, username, proxies).tap do |t|
      tickets[[service, nonce]] = t
      save_state
    end
  end

  def append(service, ticket)
    uri = URI.parse(service)
    qhash = Rack::Utils.parse_query(uri.query)
    qhash['ticket'] = ticket.nonce
    uri.query = Rack::Utils.build_query(qhash)
    uri.to_s
  end

  def ticket_for(service, nonce)
    tickets[[service, nonce]]
  end

  def tgt(session)
    ticket_for(:any, session['tgt'])
  end

  def gen_tgt(session, username)
    ticket = gen_ticket(:any, nonce('TGT'), username)
    session['tgt'] = ticket.nonce
  end

  def gen_pgt(callback_url, st)
    pgt_iou = gen_ticket(:any, nonce('PGTIOU'), st.username)
    pgt = gen_ticket(:any, 'PGT', st.username)

    url = URI.parse(callback_url).tap do |u|
      u.query = build_query(:pgtId => pgt.nonce, :pgtIou => pgt_iou.nonce)
    end

    h = Net::HTTP.new(url.host, url.port).tap do |h|
      h.verify_mode = OpenSSL::SSL::VERIFY_NONE
      h.use_ssl = true
    end

    resp = h.get(url)
    raise 'PGT generation failed' unless Net::HTTPSuccess === resp

    [pgt, pgt_iou]
  end

  def mandate(request, params)
    missing = params.select { |p| !request[p] || request[p].empty? }

    if !missing.empty?
      raise "Missing required parameters #{missing.join(', ')}"
    end
  end

  post '/_reset' do
    tickets.clear
    credentials.clear
    save_state

    status 204
  end

  post '/_accept' do
    username = request['username']
    password = request['password']

    credentials[username] = password
    save_state

    status 201
  end

  get '/' do
    redirect '/login'
  end

  get '/login' do
    if tgt(session)
      call env.merge('REQUEST_METHOD' => 'POST')
    else
      service = request['service'] || ''

      content_type :html
      status 200

      %Q{
        <!DOCTYPE html>
        <html>
          <head>
            <title>CAS</title>
          </head>
          <body>
            <form method="POST" action="/login">
              <input type="text" name="username">
              <input type="password" name="password">
              <input type="hidden" name="lt" value="useless">
              <input type="hidden" name="service" value="#{service}">
              <input type="submit">
            </form>
          </body>
        </html>
      }
    end
  end

  get '/logout' do
    session.clear

    "You have successfully logged out"
  end

  post '/login' do
    if (tgt = tgt(session))
      service = request['service']

      if service && !service.empty?
        ticket = gen_ticket(service, nonce('ST'), tgt.username)
        target = append(service, ticket)
        redirect target
      else
        status 200
        "You have successfully logged in"
      end
    else
      mandate request, %w(username password)

      username = request['username']
      password = request['password']
      service = request['service']

      if credentials.has_key?(username) && credentials[username] == password
        gen_tgt(session, username)
        call env
      else
        status 401
        "Unauthorized"
      end
    end
  end

  get '/serviceValidate' do
    mandate request, %w(service ticket)

    service = request['service']
    nonce = request['ticket']
    callback_url = request['pgtUrl']

    ticket = ticket_for(service, nonce)

    if ticket && !ticket.used?
      ticket.used = true

      status 200

      if callback_url && !callback_url.empty?
        pgt, pgt_iou = gen_pgt(callback_url, ticket)

        %Q{
          <cas:serviceResponse xmlns:cas="http://www.yale.edu/tp/cas">
            <cas:authenticationSuccess>
              <cas:user>#{ticket.username}</cas:user>
              <cas:proxyGrantingTicket>#{pgt_iou.nonce}</cas:proxyGrantingTicket>
            </cas:authenticationSuccess>
          </cas:serviceResponse>
        }
      else
        %Q{
          <cas:serviceResponse xmlns:cas="http://www.yale.edu/tp/cas">
            <cas:authenticationSuccess>
              <cas:user>#{ticket.username}</cas:user>
            </cas:authenticationSuccess>
          </cas:serviceResponse>
        }
      end
    else
      status 401

      %Q{
        <cas:serviceResponse xmlns:cas="http://www.yale.edu/tp/cas">
          <cas:authenticationFailure code="INVALID_TICKET">
          </cas:authenticationFailure>
        </cas:serviceResponse>
      }
    end
  end

  get '/proxyValidate' do
    call env.merge('PATH_INFO' => '/serviceValidate')
  end

  get '/proxy' do
    mandate request, %w(pgt targetService)

    pgt = request['pgt']
    service = request['targetService']

    ticket = ticket_for(:any, pgt)

    if ticket
      pt = gen_ticket(service, nonce('PT'), ticket.username, [request.ip])
      status 200

      %Q{
        <cas:serviceResponse xmlns:cas="http://www.yale.edu/tp/cas">
          <cas:proxySuccess>
            <cas:proxyTicket>#{pt.nonce}</cas:proxyTicket>
          </cas:proxySuccess>
        </cas:serviceResponse>
      }
    else
      status 401

      %Q{
        <cas:serviceResponse xmlns:cas="http://www.yale.edu/tp/cas">
          <cas:authenticationFailure code="INVALID_TICKET">
          </cas:authenticationFailure>
        </cas:serviceResponse>
      }
    end
  end

  run! if app_file == $0
end
