require 'aker'

# can't do just core_ext/string in AS 2.3
require 'active_support/core_ext'

module Aker
  ##
  # The representation of a configuration for the aker system,
  # including authorities, application attributes, and authentication
  # modes.
  class Configuration
    class << self
      ##
      # The default set of {Slice slices}. These will be applied to
      # all newly created instances. Changes to this array will not be
      # reflected in existing configurations instances.
      #
      # @since 2.2.0
      # @return [Array<Slice>]
      def default_slices
        @default_slices ||= []
      end

      ##
      # Appends a slice to the default set of slices. A slice may be
      # specified either as a {Slice} instance or as a block provided
      # directly to this method.
      #
      # @example from an instance
      #   class SomeSlice < Aker::Configuration::Slice
      #     def initialize
      #       super do
      #         register_authority :static, Aker::Authorities::Static
      #       end
      #     end
      #   end
      #   Aker::Configuration.add_default_slice(SomeSlice.new)
      # @example from a block
      #   Aker::Configuration.add_default_slice do
      #     register_authority :static, Aker::Authorities::Static
      #   end
      #
      # @since 2.2.0
      # @param [Slice] slice the slice to add, if a block isn't
      #   provided.
      # @return [void]
      def add_default_slice(slice=nil, &block)
        if slice
          default_slices << slice
        end
        if block
          default_slices << Slice.new(&block)
        end
      end
    end

    ##
    # Creates a new configuration.  If a block is given, it will be
    # evaluated using the {ConfiguratorLanguage DSL} and appended to
    # the new instance.
    #
    # @param [Hash] options
    #
    # @option options [Array<Slice>] :slices substitutes a set of
    #   slices for the {.default_slices globally-configured defaults}.
    #   This will only be necessary in very rare situations.
    def initialize(options={}, &config)
      (options[:slices] || self.class.default_slices).each do |slice|
        self.enhance(&slice.contents)
      end
      self.enhance(&config) if config
    end

    ##
    # Updates the configuration via the {ConfiguratorLanguage DSL}.
    #
    # @return [Configuration] itself
    def enhance(&additional_config)
      Configurator.new(self, &additional_config)
      self
    end

    ##
    # @return [Symbol] the name of the configured interactive authentication
    #   mode.  Default is `:form`.
    def ui_mode
      @ui_mode ||= :form
    end

    ##
    # Sets the interactive authentication mode.
    # @param [#to_sym, nil] ui_mode the name of the new mode; if nil,
    #   reset to the default
    # @return [void]
    def ui_mode=(ui_mode)
      @ui_mode = nil_or_sym(ui_mode)
    end

    ##
    # @return [Array<Symbol>] the names of the configured non-interactive
    #   authentication modes.  Default is an empty list.
    def api_modes
      @api_modes ||= []
    end

    ##
    # Replaces the non-interactive authentication modes.
    # @param [List<#to_sym>] new_modes the names of the desired modes
    # @return [void]
    def api_modes=(*new_modes)
      new_modes = new_modes.first if new_modes.size == 1 && Array === new_modes.first
      @api_modes = new_modes.compact.collect(&:to_sym)
    end
    alias :api_mode= :api_modes=

    ##
    # @return [Symbol] the portal to which this application belongs
    def portal
      raise "No portal configured" unless portal?
      @portal
    end

    ##
    # Set the portal to which this application belongs
    # @param [#to_sym] the new portal's name
    # @return [void]
    def portal=(portal)
      @portal = nil_or_sym(portal)
    end

    ##
    # @return [Boolean] true if there is a portal set, else false
    def portal?
      @portal
    end

    ##
    # Returns the actual authority objects created based on the last
    # call to {#authorities=}.  Note that "authority" is concept and a
    # set of methods (all of them optional), not a base class; see
    # {Aker::Authorities::Composite} for more details.
    #
    # @return [Array<Object>] the actual authority objects specified
    #   by this configuration
    def authorities
      raise "No authorities configured" unless authorities?
      @authorities
    end

    ##
    # Set the authorities for this configuration.
    #
    # @param [Array<Symbol, String, Class, Object>] new_authorities
    #   each authority specification may take one of four forms.
    #
    #   * A `Symbol` or a `String` will be resolved as an alias per
    #     the {#authority_aliases}. The {Aker::Authorities}
    #     documentation lists the built-in aliases. Extensions may
    #     provide others.
    #   * A `Class` will be instantiated, passing the
    #     configuration (this object) as the sole constructor
    #     parameter.
    #   * Any other object will be used unchanged.
    #
    # @return [void]
    def authorities=(new_authorities)
      @authorities = new_authorities.collect { |a| build_authority(a) }
    end

    ##
    # @return [Boolean] true if there are any authorities configured
    def authorities?
      @authorities && !@authorities.empty?
    end

    ##
    # Exposes a single object which aggregates all the authorities in
    # this configuration.
    #
    # @return [Aker::Authorities::Composite]
    def composite_authority
      @composite_authority ||= Aker::Authorities::Composite.new(self)
    end

    ##
    # Returns the parameters for a particular group.  Never returns `nil`.
    #
    # @param [Symbol] group the group of parameters to return
    # @return [Hash] the parameters of the specified group.
    def parameters_for(group)
      @parameter_groups ||= { }
      @parameter_groups[group] ||= { }
    end

    ##
    # Merges the given parameters into the specified group's.
    #
    # @param [Symbol] group the target group
    # @param [Hash] params the parameters to merge in
    # @return [void]
    def add_parameters_for(group, params)
      nested_merge!(parameters_for(group), params)
    end

    ##
    # Loads parameters from the given aker central parameters
    # file.
    #
    # @param [String] filename the filename
    # @return [void]
    def central(filename)
      params = ::Aker::CentralParameters.new(filename)

      params.each { |k, v| add_parameters_for(k, v) }
    end

    ##
    # Register an alias for an authority object. The alias is a symbol
    # (or something that can be turned into one). The authority object
    # is any single element that can be passed to {#authorities=}.
    #
    # Aker does and Aker extensions may define shorter aliases for
    # the authorities that they provide. In general, it's not expected
    # that applications, even if they provide their own authorities,
    # will need to configure aliases.
    #
    # @param name [#to_sym] the alias itself
    # @param authority [Symbol,String,Class,Object] the authority
    #   object to alias. See {#authorities=} for more details.
    # @return [void]
    def alias_authority(name, authority)
      authority_aliases[name.to_sym] = authority
    end

    ##
    # @see #alias_authority
    # @return [Hash] the map of aliases to authority objects.
    def authority_aliases
      @authority_aliases ||= {}
    end

    ##
    # Register a mode class to be used in this configuration. A mode
    # class is Warden strategy with some additional aker elements on
    # top.
    #
    # Aker and Aker extensions register the the modes that they
    # provide (using {Slice slices}), so an application only needs to
    # invoke this method if it provides its own custom mode.
    #
    # @see #registered_modes
    # @see Aker::Modes::Base
    # @since 2.2.0
    # @param mode_class [Class]
    # @return [void]
    def register_mode(mode_class)
      fail "#{mode_class.inspect} is not usable as a Aker mode" unless mode_class.respond_to?(:key)
      registered_modes << mode_class
    end

    ##
    # The mode classes that have been registered for use in this
    # configuration.
    #
    # @see #register_mode
    # @return [Array<Class>]
    def registered_modes
      @registered_modes ||= []
    end

    ##
    # Register a middleware-building block that will be used to insert
    # middleware either before or after the Aker
    # {Aker::Rack::Authenticate authentication middleware}. This
    # method requires a block. When it is time to actually install the
    # middleware, the block will be yielded an object which behaves
    # like a `Rack::Builder`. The block should attach any middleware
    # it wishes to install using `use`.
    #
    # Unlike the middleware associated with modes, this middleware
    # will be inserted in the stack in regardless of any other
    # settings.
    #
    # This method is primarily intended for Aker and Aker
    # extensions. Applications have complete control over their
    # middleware stacks and so may build them however is appropriate.
    #
    # @example
    #   config.register_middleware_installer(:before_authentication) do |builder|
    #     builder.use IpFilter, '10.0.8.9'
    #   end
    #
    # @see #install_middleware
    # @see Aker::Rack.use_in
    #
    # @param [:before_authentication,:after_authentication] where the
    #   relative location in the stack at which this installer should
    #   be invoked.
    # @yield [#use] a Rack::Builder. Note that the yield is deferred
    #   until {#install_middleware} is invoked.
    # @return [void]
    def register_middleware_installer(where, &installer)
      verify_middleware_location(where)
      (middleware_installers[where] ||= []) << installer
    end

    ##
    # @private exposed for testing
    def middleware_installers
      @middleware_installers ||= {}
    end

    ##
    # Installs the middleware configured under the given key in the
    # given `Rack::Builder}. This method is primarily for internal
    # library use.
    #
    # @see #register_middleware_installer
    # @param [:before_authentication,:after_authentication] where the
    #   set of middleware installers to use.
    # @param [#use] builder the `Rack::Builder`-like object into which
    #   the middleware will be installed.
    # @return [void]
    def install_middleware(where, builder)
      verify_middleware_location(where)
      (middleware_installers[where] || []).each do |installer|
        installer.call(builder)
      end
    end

    def verify_middleware_location(where)
      unless [:before_authentication, :after_authentication].include?(where)
        fail "Unsupported middleware location #{where.inspect}."
      end
    end
    private :verify_middleware_location

    ##
    # Retrieves the logger which aker will use for internal messages.
    #
    # The default instance logs to standard error.
    #
    # @return [Object] an object which conforms to the
    #   protocol of ruby's built-in Logger class
    def logger
      @logger ||= Logger.new($stderr)
    end

    ##
    # Specifies the logger aker will use for internal messages.
    #
    # @param [Object] logger an object which conforms to the protocol
    #   of ruby's built-in Logger class
    def logger=(logger)
      @logger = logger
    end

    private

    def nil_or_sym(x)
      x ? x.to_sym : x
    end

    def build_authority(spec)
      case spec
      when Symbol
        resolve_alias(spec)
      when String
        resolve_alias(spec)
      when Class
        instantiate_authority(spec)
      else # assume it's an instance
        spec
      end
    end

    def instantiate_authority(clazz)
      clazz.new(self)
    end

    def resolve_alias(name)
      resolved_spec = authority_aliases[name.to_sym]
      fail "Unknown authority alias #{name.inspect}." unless resolved_spec
      build_authority resolved_spec
    end

    def nested_merge!(target, overrides)
      overrides.each_pair do |k, v|
        if v.respond_to?(:each_pair)
          if target.has_key?(k)
            nested_merge!(target[k], overrides[k])
          else
            target[k] = overrides[k]
          end
        else
          target[k] = v
        end
      end
      target
    end

    ##
    # A persistent, reappliable fragment of a {Aker::Configuration}.
    # This class enables Aker extensions to provide default chunks of
    # configuration that will apply to every newly-created
    # configuration instance.
    #
    # In general this facility is not needed by applications that use
    # Aker; it's intended only for libraries that provide additional
    # functionality on top of Aker and need to provide reasonable
    # defaults and/or mandatory infrastructure for those features.
    #
    # Extensions of that kind should create an instance of this class
    # and register it with {Aker::Configuration.add_default_slice}
    # (or pass a block to that method to have it create one on their
    # behalf).
    #
    # @since 2.2.0
    class Slice
      ##
      # @return [Proc] the configuration DSL fragment comprising this
      #   slice.
      attr_accessor :contents

      ##
      # @param contents the configuration DSL fragment comprising this
      #   slice.
      def initialize(&contents)
        @contents = contents
      end
    end
  end

  ##
  # This module provides a DSL adapter for {Configuration}.
  #
  # @example
  #     Aker.configure {
  #       portal :ENU
  #       authorities :ldap, :static
  #       api_mode :basic
  #       central "/etc/nubic/aker-prod.yml"
  #       ldap_parameters :server => 'ldap.example.org'
  #       after_authentication_middleware do |builder|
  #         builder.use RequestLogger
  #       end
  #     }
  #
  # Notes:
  #
  #   * All setters in {Configuration} are accessible from the DSL,
  #     except that you don't use '='.
  #   * Other methods which accept arguments are also available.
  #   * As shown above, there is sugar for setting other parameters.
  #     "*name*_parameters *hash*" adds to the
  #     {Configuration#parameters_for parameters} for group *name*.
  #   * Also as shown above, there is sugar for calling
  #     {Configuration#register_middleware_installer}.
  #   * `this` refers to the configuration being updated (for the rare
  #     case that you would need to pass it directly to some constructor).
  module ConfiguratorLanguage
    ##
    # @private
    def authorities(*authorities)
      @specified_authorities = authorities
    end
    alias authority authorities

    ##
    # @private
    def method_missing(m, *args, &block)
      if m.to_s =~ /(\S+)_parameters?$/
        @config.add_parameters_for($1.to_sym, args.first)
      elsif m.to_s =~/(\S+)_middleware$/
        @config.register_middleware_installer($1.to_sym, &block)
      elsif @config.respond_to?(:"#{m}=")
        @config.send(:"#{m}=", *args)
      elsif @config.respond_to?(m)
        @config.send(m, *args)
      else
        super
      end
    end

    ##
    # @private
    def this
      @config
    end

    ##
    # @private
    def deferred_setup
      @config.authorities = @specified_authorities if @specified_authorities
    end
  end

  ##
  # @private
  class Configurator
    include ConfiguratorLanguage

    def initialize(target, &block)
      @config = target
      evaluate(&block)
    end

    private

    def evaluate(&block)
      instance_eval(&block)
      deferred_setup
    end
  end
end
