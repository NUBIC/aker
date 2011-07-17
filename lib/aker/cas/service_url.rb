require 'aker/cas'

module Aker::Cas
  ##
  # Provides logic for reconstructing the full requested URL from a
  # rack request.
  #
  # If used as a mixin, the host class must have a `#request`
  # accessor. It may optionally also have a `#attempted_path`
  # accessor.
  #
  # @see ServiceMode
  # @see Aker::Modes::Support::AttemptedPath
  module ServiceUrl
    ##
    # The service URL supplied to the CAS login page.  This is the
    # requested URL, sans any service ticket.
    #
    # @return [String]
    def service_url
      ServiceUrl.service_url(
        request,
        (attempted_path if self.respond_to?(:attempted_path))
      )
    end

    ##
    # Builds the service URL that should be used for the given
    # request. This is the requested URL (or the attempted_path, if
    # given), sans any service ticket.
    #
    # @param [Rack::Request] request
    # @param [String] attempted_path
    # @return [String]
    def self.service_url(request, attempted_path=nil)
      requested = URI.parse(
        if attempted_path
          url = "#{request.scheme}://#{request.host}"

          unless [ ["https", 443], ["http", 80] ].include?([request.scheme, request.port])
            url << ":#{request.port}"
          end

          url << attempted_path
        else
          request.url
        end
                           )
      if requested.query
        requested.query.gsub!(/(&?)ticket=ST-[^&]+(&?)/) do
          if [$1, $2].uniq == ['&'] # in the middle
            '&'
          else
            nil
          end
        end
        requested.query = nil if requested.query.empty?
      end
      requested.to_s
    end
  end
end
