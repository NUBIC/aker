Given /^I have an authority that accepts these usernames and passwords:$/ do |table|
  static = Bcsec::Authorities::Static.new
  table.hashes.each do |u|
    static.valid_credentials!(:user, u['username'], u['password'])
  end
  Bcsec.configure { authority static }
end

Given /^I have a bcsec\-protected application using$/ do |table|
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

  @app = Rack::Builder.new do
    use Rack::Session::Cookie
    Bcsec::Rack.use_in(self)

    map '/protected' do
      run Proc.new { |env|
        throw :warden unless env['warden'].authenticated?
        [200, { "Content-Type" => "text/plain" },
         ["I'm protected, #{env['warden'].user.username}."]]
      }
    end

    map '/' do
      run Proc.new { |env|
        user = env['warden'].user
        [
          200,
          { "Content-Type" => "text/plain" },
          ["Anyone can see this.", ("Even #{user.username}." if user)].compact.join("\n")
        ]
      }
    end
  end
end

After do
  Bcsec.configuration = nil
end
