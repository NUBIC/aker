require 'bcsec/modes/support'

module Bcsec::Modes::Support
  ##
  # If a user fails authentication, the URL that user was trying to access is
  # stored in the `:attempted_path` key in the `warden.options` environment
  # variable.
  #
  # AttemptedPath provides code to extract the attempted path that can be
  # shared amongst objects that need this information.
  module AttemptedPath
    ##
    # Returns the path that a user was trying to access.
    #
    # @return [String, nil] a String if a path exists, nil otherwise
    def attempted_path
      if env['warden.options']
        env['warden.options'][:attempted_path]
      end
    end
  end
end
