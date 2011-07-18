require 'restclient'

module Aker
  module Cucumber
    module RackEndpoints
      class << self
        def public
          Proc.new { |env|
            user = env['warden'].user
            [
             200,
             { "Content-Type" => "text/plain" },
             ["Anyone can see this.", ("  Even #{user.username}." if user)].compact
            ]
          }
        end

        def authentication_required
          Proc.new { |env|
            env['aker'].authentication_required!
            [200, { "Content-Type" => "text/plain" },
             ["I'm protected, #{env['warden'].user.username}."]]
          }
        end
        alias :authenticated_api_resource :authentication_required

        def search
          Proc.new { |env|
            env['aker'].authentication_required!
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
            env['aker'].permit! group.to_sym
            [200, { "Content-Type" => "text/plain" },
             ["Only #{group.downcase} can see this page at all."]]
          }
        end

        def partial_group(group)
          Proc.new { |env|
            body = "This page is visible to everyone"
            env['aker'].permit?(group) do
              body << "\nBut there is special content for #{group}"
            end

            [200, { "Content-Type" => "text/plain" },
             [body]]
          }
        end

        def cas_api_consumer(api_base_url, resource_relative_url)
          Proc.new { |env|
            env['aker'].authentication_required!

            content = with_proxy_ticket(api_base_url, env) do |pt|
              RestClient.get(URI.join(api_base_url, resource_relative_url).to_s,
                             :Authorization => "CasProxy #{pt}")
            end

            [200, { "Content-Type" => "text/plain" },
             ["The API said: #{content}"]]
          }
        end

        ##
        # When the user is authenticated, this endpoint uses CAS proxy
        # authentication in the same manner as {#cas_api_consumer} -- however,
        # it also memoizes that response for later replay.
        #
        # When the user is _not_ authenticated, this endpoint uses the cookies
        # from the previously memoized response (and blows up if there isn't one
        # -- so it's a pretty stupid malicious endpoint) and tries to make an
        # API request with those cookies.
        def cas_api_replayer(api_base_url, resource_relative_url)
          api_endpoint = URI.join(api_base_url, resource_relative_url).to_s
          memoized_response = nil

          Proc.new { |env|
            content = if env['aker'].authenticated?
                        resp = with_proxy_ticket(api_base_url, env) do |pt|
                          RestClient.get(api_endpoint, :Authorization => "CasProxy #{pt}")
                        end

                        memoized_response = resp
                      else
                        RestClient.get(api_endpoint, { :cookie => memoized_response.headers[:set_cookie] })
                      end

            [200, { "Content-Type" => "text/plain" },
             ["The API said: #{content}"]]
          }
        end

        private

        def with_proxy_ticket(service_url, env)
          yield env['warden'].user.cas_proxy_ticket(service_url[0,service_url.size-1])
        end
      end
    end
  end
end
