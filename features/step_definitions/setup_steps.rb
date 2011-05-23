After do
  Bcsec.configuration = nil
end

Given /^I have an authority that accepts these usernames and passwords:$/ do |table|
  static = Bcsec::Authorities::Static.new
  table.hashes.each do |u|
    static.valid_credentials!(:user, u['username'], u['password'])
  end
  Bcsec.configure { authority static }
end

Given /^(\w+) is in (?:the (.*?) groups? for )?(\w+)$/ do |username, group_clause, portal|
  static = Bcsec.configuration.authorities.find { |a| Bcsec::Authorities::Static === a }
  raise "No static authority configured" unless static
  static.user(username) do |user|
    user.portals << portal.to_sym
    user.default_portal = portal.to_sym unless user.default_portal
    if group_clause
      group_clause.gsub(/ and /, ' ').split(/[\s,]+/).each do |group|
        user.group_memberships(portal) << Bcsec::GroupMembership.new(Bcsec::Group.new(group))
      end
    end
  end
end

Given /^I have a CAS server that accepts these usernames and passwords:$/ do |table|
  table.hashes.each do |u|
    @cas_server.register_user(u['username'], u['password'])
  end
  cas = @cas_server
  Bcsec.configure {
    cas_parameters :base_url => cas.base_url
  }
end

Given /^I have a bcsec\-protected application using$/ do |bcsec_params|
  enhance_configuration_from_table(bcsec_params)

  app = Rack::Builder.new do
    use Rack::Session::Cookie
    Bcsec::Rack.use_in(self)

    map '/protected' do
      run Bcsec::Cucumber::RackEndpoints.authentication_required
    end

    map '/search' do
      run Bcsec::Cucumber::RackEndpoints.search
    end

    map '/owners' do
      run Bcsec::Cucumber::RackEndpoints.group_only("Owners")
    end

    map '/shared' do
      run Bcsec::Cucumber::RackEndpoints.partial_group("Owners")
    end

    map '/' do
      run Bcsec::Cucumber::RackEndpoints.public
    end
  end

  start_main_rack_server(app)
end

Given /^I have a bcsec\-protected RESTful API using$/ do |bcsec_params|
  config = Bcsec::Configuration.new
  if (@cas_server)
    config.parameters_for(:cas)[:base_url] = @cas_server.base_url
  end
  enhance_configuration_from_table(bcsec_params, config)

  api_app = Rack::Builder.new do
    use Rack::Session::Cookie
    Bcsec::Rack.use_in(self, config)

    map '/a-resource' do
      run Bcsec::Cucumber::RackEndpoints.authenticated_api_resource
    end

    map '/' do
      run Bcsec::Cucumber::RackEndpoints.public
    end
  end

  @api_server = start_rack_server(api_app, 5427)
end

Given /^I have a bcsec\-protected consumer of a CAS\-protected API$/ do
  pgt_app = Bcsec::Cas::RackProxyCallback.application(:store => "#{tmpdir}/pgt_store")
  pgt_server = start_rack_server(pgt_app, 5310, :ssl => true)

  Bcsec.configuration.
    parameters_for(:cas)[:proxy_retrieval_url] = URI.join(pgt_server.base_url, "retrieve_pgt").to_s
  Bcsec.configuration.
    parameters_for(:cas)[:proxy_callback_url] = URI.join(pgt_server.base_url, "receive_pgt").to_s

  Bcsec.configure {
    authority :cas
    ui_mode :cas
  }

  api_server = @api_server
  app = Rack::Builder.new do
    use Rack::Session::Cookie
    Bcsec::Rack.use_in(self)

    map '/consume' do
      run Bcsec::Cucumber::RackEndpoints.
        cas_api_consumer(api_server.base_url, "/a-resource")
    end

    map '/replaying' do
      run Bcsec::Cucumber::RackEndpoints.
        cas_api_replayer(api_server.base_url, "/a-resource")
    end

    map '/protected' do
      run Bcsec::Cucumber::RackEndpoints.authentication_required
    end

    map '/' do
      run Bcsec::Cucumber::RackEndpoints.public
    end
  end

  start_main_rack_server(app)
end

Given /^the application has a session timeout of (\d+) seconds$/ do |timeout|
  Bcsec.configuration.add_parameters_for(:policy, %s(session-timeout) => timeout)

  stop_spawned_servers
  start_main_rack_server(app)
end
