Given /^I have an authority that accepts these usernames and passwords:$/ do |table|
  static = Bcsec::Authorities::Static.new
  table.hashes.each do |u|
    static.valid_credentials!(:user, u['username'], u['password'])
  end
  Bcsec.configure { authority static }
end

Given /^I have a CAS server that accepts these usernames and passwords:$/ do |table|
  table.hashes.each do |u|
    @cas_server.register_user(u['username'], u['password'])
  end
  cas = @cas_server
  Bcsec.configure {
    authority :cas
    cas_parameters :base_url => cas.base_url
  }
end

Given /^I have bcsec configured like so$/ do |table|
  string_conf = table.hashes.first
  Bcsec.configure {
    string_conf.each_pair do |attr, value|
      value =
        case attr
        when /mode/
          value.split(' ')
        else
          value
        end
      if value && !value.empty?
        self.send(attr.to_sym, *value)
      end
    end
  }
end

After do
  Bcsec.configuration = nil
end

Given /^I have a bcsec\-protected application using$/ do |bcsec_params|
  Given "I have bcsec configured like so", bcsec_params

  @app = Rack::Builder.new do
    use Rack::Session::Cookie
    Bcsec::Rack.use_in(self)

    map '/protected' do
      run Bcsec::Cucumber::RackEndpoints.authentication_required
    end

    map '/' do
      run Bcsec::Cucumber::RackEndpoints.public
    end
  end

  Capybara.app = @app
end

After do
  Bcsec.configuration = nil
end
