require 'aker'
require 'yaml'

module Aker
  ##
  # Provides consistent access to server-based defaults for
  # configuration parameters. These defaults are stored in a YAML file
  # on the server and updated separately from application
  # deployments. E.g., you might have the following in
  # /etc/nubic/aker-prod.yml:
  #
  #     ldap:
  #       server: ldap.example.org
  #       user: cn=foo
  #       password: 13635;nefvqerg35245gk
  #     policy:
  #       session_timeout_seconds: 1500
  #
  # The top level keys in this file correspond to parameter groups in
  # a {Aker::Configuration}. If this file were loaded like so,
  #
  #     Aker.configure {
  #       central '/etc/nubic/aker-prod.yml'
  #     }
  #
  # it would be equivalent to the following:
  #
  #     Aker.configure {
  #       ldap_parameters :server => 'ldap.example.org',
  #                       :user => 'cn=foo',
  #                       :password => '13635;nefvqerg35245gk'
  #       policy_parameters :session_timeout_seconds => 1500
  #     }
  #
  # The `central` approach has several benefits:
  #
  # * It is simultaneously updateable for all applications on a
  #   server.
  # * It separates system administration tasks from application
  #   developer concerns.
  # * It provides an easy alternative to checking sensitive
  #   information (in this example, the LDAP password) into the VCS.
  # * No flexibility is lost &mdash; individual applications may still
  #   override parameter values if necessary.
  #
  # @see https://github.com/NUBIC/bcdatabase
  #      Bcdatabase: a tool which provides similar capabilities for
  #      database and service configurations.
  class CentralParameters < Hash
    ##
    # Creates a new instance with the given overrides.
    #
    # @param [String, Hash] values if a hash, it is used as a set of
    #   overrides directly.  Otherwise it is interpreted as the filename
    #   for the system central parameters YAML file.
    def initialize(values = {})
      super

      unless values.is_a? Hash
        values = YAML::load( File.open(values) )
      end

      values = nested_symbolize_keys!(deep_clone(values))
      update(values)
    end

    ##
    # Returns the value or (more likely) hash of values corresponding
    # to the given top-level configuration section.
    #
    # Note that, no matter the structure of the values hash provided
    # on construction, all keys in any hashes returned by this method
    # will be symbols.
    #
    # @param [Symbol] key the configuration section to access
    def [](key)
      super
    end

    #######
    private

    def deep_clone(src)
      clone = { }
      src.each_pair do |k, v|
        clone[k] = v.is_a?(Hash) ? deep_clone(v) : v
      end
      clone
    end

    def nested_symbolize_keys!(target)
      target.keys.each do |k|
        v = target[k]
        nested_symbolize_keys!(v) if v.respond_to?(:keys)
        target.delete(k)
        target[k.to_sym] = v
      end
      target
    end
  end
end
