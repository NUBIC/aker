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
            env['bcsec'].authentication_required!
            [200, { "Content-Type" => "text/plain" },
             ["I'm protected, #{env['warden'].user.username}."]]
          }
        end
        alias :authenticated_api_resource :authentication_required

        def search
          Proc.new { |env|
            env['bcsec'].authentication_required!
            request = ::Rack::Request.new(env)

            [200, { "Content-Type" => "text/plain" },
              ["Format: ",
                request.params["format"],
                ", ",
                "results: ",
                request.params["q"]].compact]
          }
        end

        def group_only(group)
          Proc.new { |env|
            env['bcsec'].permit! group.to_sym
            [200, { "Content-Type" => "text/plain" },
             ["Only #{group.downcase} can see this page at all."]]
          }
        end

        def partial_group(group)
          Proc.new { |env|
            body = "This page is visible to everyone"
            env['bcsec'].permit?(group) do
              body << "\nBut there is special content for #{group}"
            end

            [403, { "Content-Type" => "text/plain" },
             [body]]
          }
        end

        def cas_api_consumer(api_base_url, resource_relative_url)
          Proc.new { |env|
            env['bcsec'].authentication_required!

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
