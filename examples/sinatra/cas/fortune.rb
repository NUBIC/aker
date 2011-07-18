require 'rest_client'

##
# This model wraps our fortune API in a RestClient shell.
class Fortune < RestClient::Resource
  ##
  # A proxy ticket factory object.  Must respond to `#cas_proxy_ticket` with a
  # valid CAS proxy ticket in the form of a String.
  #
  # `Aker::User`, in a CAS situation, satisfies the above interface.
  #
  # @return [#cas_proxy_ticket]
  attr_accessor :proxy_ticket_factory

  ##
  # The ID of this fortune.
  #
  # @return [Integer]
  attr_accessor :id

  ##
  # The fortune itself.
  #
  # @return [String]
  attr_accessor :value

  class << self
    ##
    # The base URI for the fortune service.
    #
    # @return [String]
    attr_accessor :base_uri

    ##
    # The CAS proxy service URI for the fortune service.
    #
    # @return [String]
    attr_accessor :service_uri
  end

  ##
  # Retrieves all fortunes.
  #
  # @param user [Aker::User] the user to proxy
  # @return [Array<Fortune>] a list of fortunes
  def self.all(user)
    fortune = new
    fortune.proxy_ticket_factory = user

    JSON.parse(fortune.get.to_s).map { |hash| Fortune.from_hash(hash) }
  end

  ##
  # Retrives a fortune by ID.  Doesn't do error-handling at all.
  #
  # @param id [Integer] a fortune ID
  # @param user [Aker::User] the user to proxy
  # @return [String] a fortune
  def self.find(id, user)
    fortune = new[id]
    fortune.proxy_ticket_factory = user

    Fortune.from_hash(JSON.parse(fortune.get.to_s))
  end

  ##
  # Destroys a fortune.
  #
  # @param id [Integer] a fortune ID
  # @param user [Aker::User] the user to proxy
  # @return [void]
  def self.destroy(id, user)
    fortune = new[id]
    fortune.proxy_ticket_factory = user

    fortune.delete
  end

  ##
  # Creates a fortune.
  #
  # @param value [String]
  # @param user [Aker::User] the user to proxy
  # @return [Fortune]
  def self.create(value, user)
    fortune = new
    fortune.proxy_ticket_factory = user

    response = fortune.post({'fortune' => value}.to_json)

    resource = response.headers[:location]
    id = resource.match(/(\d+)$/)[1]

    Fortune.from_hash('fortune' => fortune, 'id' => id)
  end

  ##
  # Makes a Fortune object from a hash.
  #
  # @param hash [Hash] hash of key-value pairs
  # @return Fortune
  def self.from_hash(hash)
    id = hash['id'].to_i

    fortune = new[id]
    fortune.id = id
    fortune.value = hash['fortune']
    fortune
  end

  ##
  # Constructs an instance of this model.  If `url` is given, it will be used
  # for requests; otherwise, `base_uri` will be used.
  #
  # The `options`, `backwards_compatibility`, and block are passed to the
  # superclass.
  #
  # @param options [Hash]
  # @param backwards_compatibility [Boolean]
  def initialize(url = nil, options = {}, backwards_compatibility = nil, &block)
    super(url || self.class.base_uri, options, backwards_compatibility, &block)
  end

  ##
  # Updates a fortune.
  #
  # @param fortune [String] the new value of the fortune
  # @param user [Aker::User] the user to proxy
  # @return [self]
  def update(fortune, user)
    self.proxy_ticket_factory = user

    put({'fortune' => fortune}.to_json)

    self
  end

  ##
  # An override of `RestClient::Resource#get` that appends an Authorization
  # header with a CAS proxy ticket challenge, as expected by aker's CAS proxy
  # implementation.
  #
  # @param additional_headers [Hash] additional headers for the request
  # @yield [response] the HTTP response
  def get(additional_headers = {}, &block)
    super(additional_headers.merge(:authorization => 'CasProxy ' + get_proxy_ticket), &block)
  end

  ##
  # An override of `RestClient::Resource#delete` that appends an Authorization
  # header with a CAS proxy ticket challenge, as expected by aker's CAS proxy
  # implementation.
  #
  # @param additional_headers [Hash] additional headers for the request
  # @yield [response] the HTTP response
  def delete(additional_headers = {}, &block)
    super(additional_headers.merge(:authorization => 'CasProxy ' + get_proxy_ticket), &block)
  end

  ##
  # An override of `RestClient::Resource#post` that appends an Authorization
  # header with a CAS proxy ticket challenge, as expected by aker's CAS proxy
  # implementation.
  #
  # @param payload [String] the content to POST
  # @param additional_headers [Hash] additional headers for the request
  # @yield [response] the HTTP response
  def post(payload, additional_headers = {}, &block)
    super(payload, additional_headers.merge(:authorization => 'CasProxy ' + get_proxy_ticket), &block)
  end

  ##
  # An override of `RestClient::Resource#put` that appends an Authorization
  # header with a CAS proxy ticket challenge, as expected by aker's CAS proxy
  # implementation.
  #
  # @param payload [String] the content to PUT
  # @param additional_headers [Hash] additional headers for the request
  # @yield [response] the HTTP response
  def put(payload, additional_headers = {}, &block)
    super(payload, additional_headers.merge(:authorization => 'CasProxy ' + get_proxy_ticket), &block)
  end

  private

  def get_proxy_ticket
    proxy_ticket_factory.cas_proxy_ticket(self.class.service_uri)
  end
end
