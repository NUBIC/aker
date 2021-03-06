After do
  Aker.configuration = nil
end

Given /^I have an authority that accepts these usernames and passwords:$/ do |table|
  static = Aker::Authorities::Static.new
  table.hashes.each do |u|
    static.valid_credentials!(:user, u['username'], u['password'])
  end
  Aker.configure { authority static }
end

Given /^I have a ldap authority$/ do
  ls = @ladle_server
  Aker.configure {
    authority :ldap
    ldap_parameters :port => ls.port, :server => 'localhost',
      :use_tls => false, :search_domain => 'dc=example,dc=org'
  }
end

Given /^(\w+) is in (?:the (.*?) groups? for )?(\w+)$/ do |username, group_clause, portal|
  static = Aker.configuration.authorities.find { |a| Aker::Authorities::Static === a }
  raise "No static authority configured" unless static
  static.user(username) do |user|
    user.portals << portal.to_sym
    user.default_portal = portal.to_sym unless user.default_portal
    if group_clause
      group_clause.gsub(/ and /, ' ').split(/[\s,]+/).each do |group|
        user.group_memberships(portal) << Aker::GroupMembership.new(Aker::Group.new(group))
      end
    end
  end
end

Given /^I have an aker\-protected application using$/ do |aker_params|
  Aker.configuration.parameters_for(:cas)[:base_url] = cas_base_url

  enhance_configuration_from_table(aker_params)

  app = Rack::Builder.new do
    use Rack::Session::Cookie
    Aker::Rack.use_in(self)

    map '/protected' do
      run Aker::Cucumber::RackEndpoints.authentication_required
    end

    map '/search' do
      run Aker::Cucumber::RackEndpoints.search
    end

    map '/owners' do
      run Aker::Cucumber::RackEndpoints.group_only("Owners")
    end

    map '/shared' do
      run Aker::Cucumber::RackEndpoints.partial_group("Owners")
    end

    map '/custom/login' do
      run Aker::Cucumber::RackEndpoints.custom_form_login
    end

    map '/custom/logout' do
      run Aker::Cucumber::RackEndpoints.custom_form_logout
    end

    map '/' do
      run Aker::Cucumber::RackEndpoints.public
    end
  end

  start_main_rack_server(app)
end

Given /^I have an aker\-protected RESTful API using$/ do |aker_params|
  config = Aker::Configuration.new
  config.parameters_for(:cas)[:base_url] = cas_base_url
  enhance_configuration_from_table(aker_params, config)

  api_app = Rack::Builder.new do
    use Rack::Session::Cookie
    Aker::Rack.use_in(self, config)

    map '/a-resource' do
      run Aker::Cucumber::RackEndpoints.authenticated_api_resource
    end

    map '/' do
      run Aker::Cucumber::RackEndpoints.public
    end
  end

  @api_server = start_rack_server(api_app, 5427)
end

Given /^I have an aker\-protected consumer of a CAS\-protected API$/ do
  Aker.configuration.parameters_for(:cas)[:base_url] = cas_base_url
  Aker.configuration.parameters_for(:cas)[:proxy_retrieval_url] = cas_proxy_retrieval_url
  Aker.configuration.parameters_for(:cas)[:proxy_callback_url] = cas_proxy_callback_url

  Aker.configure {
    authority :cas
    ui_mode :cas
  }

  api_server = @api_server
  app = Rack::Builder.new do
    use Rack::Session::Cookie
    Aker::Rack.use_in(self)

    map '/consume' do
      run Aker::Cucumber::RackEndpoints.
        cas_api_consumer(api_server.base_url, "/a-resource")
    end

    map '/replaying' do
      run Aker::Cucumber::RackEndpoints.
        cas_api_replayer(api_server.base_url, "/a-resource")
    end

    map '/protected' do
      run Aker::Cucumber::RackEndpoints.authentication_required
    end

    map '/' do
      run Aker::Cucumber::RackEndpoints.public
    end
  end

  start_main_rack_server(app)
end
