require 'aker'
require 'yaml'

module Aker
  ##
  # Provides access to the akerurity central parameters file.
  # @see http://bcwiki.bioinformatics.northwestern.edu/bcwiki/index.php/Central_aker_configuration
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