
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
      end
    end
  end
end
