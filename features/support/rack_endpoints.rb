require 'restclient'

module Bcsec
  module Cucumber
    module RackEndpoints
      class << self
        def public
          Proc.new { |env|
            user = env['warden'].user
            [
             200,
             { "Content-Type" => "text/plain" },
             ["Anyone can see this.", ("Even #{user.username}." if user)].compact.join("\n")
            ]
          }
        end

        def authentication_required
          Proc.new { |env|
            throw :warden unless env['warden'].authenticated?
            [200, { "Content-Type" => "text/plain" },
             ["I'm protected, #{env['warden'].user.username}."]]
          }
        end
        alias :authenticated_api_resource :authentication_required

        def cas_api_consumer(api_base_url, resource_relative_url)
          Proc.new { |env|
            throw :warden unless env['warden'].authenticated?

            pt = env['warden'].user.cas_proxy_ticket(api_base_url[0,api_base_url.size-1])
            content = RestClient.get(URI.join(api_base_url, resource_relative_url).to_s,
                                     :Authorization => "CasProxy #{pt}")

            [200, { "Content-Type" => "text/plain" },
             ["The API said: #{content}"]]
          }
        end
      end
    end
  end
end
