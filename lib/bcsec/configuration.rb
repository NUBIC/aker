require 'bcsec'

# can't do just core_ext/string in AS 2.3
require 'active_support/core_ext'

module Bcsec
  ##
  # The representation of a configuration for the bcsec system,
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
      #   class SomeSlice < Bcsec::Configuration::Slice
      #     def initialize
      #       super do
      #         register_authority :static, Bcsec::Authorities::Static
      #       end
      #     end
      #   end
      #   Bcsec::Configuration.add_default_slice(SomeSlice.new)
      # @example from a block
      #   Bcsec::Configuration.add_default_slice do
      #     register_authority :static, Bcsec::Authorities::Static
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
    # {Bcsec::Authorities::Composite} for more details.
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
    #     the {#authority_aliases}. The {Bcsec::Authorities}
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
    # @return [Bcsec::Authorities::Composite]
    def composite_authority
      @composite_authority ||= Bcsec::Authorities::Composite.new(self)
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
    # Loads parameters from the given bcsec central parameters
    # file.
    #
    # @param [String] filename the filename
    # @return [void]
    def central(filename)
      params = ::Bcsec::CentralParameters.new(filename)

      params.each { |k, v| add_parameters_for(k, v) }
    end

    ##
    # Register an alias for an authority object. The alias is a symbol
    # (or something that can be turned into one). The authority object
    # is anything that can be passed to {#authority=}.
    #
    # Bcsec does and Bcsec extensions may define shorter aliases for
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
    # class is Warden strategy with some additional bcsec elements on
    # top.
    #
    # Bcsec and Bcsec extensions register the the modes that they
    # provide (using {Slice slices}), so an application only needs to
    # invoke this method if it provides its own custom mode.
    #
    # @see #registered_modes
    # @see Bcsec::Modes::Base
    # @since 2.2.0
    # @param mode_class [Class]
    def register_mode(mode_class)
      fail "#{mode_class.inspect} is not usable as a Bcsec mode" unless mode_class.respond_to?(:key)
      registered_modes << mode_class
    end

    ##
    # The mode classes that have been registered for use in this
    # configuration.
    #
    # @see #register_mode
    # @return Array<Class>
    def registered_modes
      @registered_modes ||= []
    end

    ##
    # Retrieves the logger which bcsec will use for internal messages.
    #
    # The default instance logs to standard error.
    #
    # @return [Object] an object which conforms to the
    #   protocol of ruby's built-in Logger class
    def logger
      @logger ||= Logger.new($stderr)
    end

    ##
    # Specifies the logger bcsec will use for internal messages.
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
    # A persistent, reappliable fragment of a {Bcsec::Configuration}.
    # This class enables Bcsec extensions to provide default chunks of
    # configuration that will apply to every newly-created
    # configuration instance.
    #
    # In general this facility is not needed by applications that use
    # Bcsec; it's intended only for libraries that provide additional
    # functionality on top of Bcsec and need to provide reasonable
    # defaults and/or mandatory infrastructure for those features.
    #
    # Extensions of that kind should create an instance of this class
    # and register it with {Bcsec::Configuration.add_default_slice}
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
  # This module provides a DSL adapter for {Configuration}. Example:
  #
  #     Bcsec.configure {
  #       portal :ENU
  #       authorities :netid, :pers
  #       api_mode :basic
  #       central "/etc/nubic/bcsec-prod.yml"
  #       netid_parameters :user => "me"
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
  module ConfiguratorLanguage
    ##
    # @private
    def authorities(*authorities)
      @specified_authorities = authorities
    end
    alias authority authorities

    ##
    # @private
    def method_missing(m, *args)
      if m.to_s =~ /(\S+)_parameters?$/
        @config.add_parameters_for($1.to_sym, args.first)
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
    def deferred_setup
      @config.authorities = @specified_authorities if @specified_authorities
    end
  end

  ##
  # @private
  module DeprecatedConfiguratorLanguage
    def app_name(*ignored)
      Deprecation.notify("app_name is unnecessary.  Remove it from your configuration.", "2.2")
    end

    def authenticator(*args)
      Deprecation.notify("authenticator is deprecated.  Use authority instead.", "2.2")
      authorities *args
    end

    def authenticators(*args)
      Deprecation.notify("authenticators is deprecated.  Use authorities instead.", "2.2")
      authorities *args
    end

    def authorities(*args)
      super(*replace_deprecated_authenticators(args))
    end

    # alias + module super doesn't work on MRI 1.8.x (does work on
    # 1.9.1 and JRuby 1.4.0 though)
    def authority(*args)
      authorities(*args)
    end

    {
      :server => :server,
      :username => :user,
      :password => :password
    }.each do |attr, param|
      replacement = "netid_parameters :#{param} => \#{value.inspect}"
      class_eval <<-RUBY
        def ldap_#{attr}(value)
          Deprecation.notify("ldap_#{attr} is deprecated.  Use #{replacement} instead.", "2.2")
          netid_parameters :#{param} => value
        end
      RUBY
    end

    def establish_cc_pers_connection(*args)
      Deprecation.notify("establish_cc_pers_connection is deprecated.  " <<
                         "Use pers_parameters :separate_connection => true instead.", "2.2")
      pers_parameters :separate_connection => true
    end

    private

    def replace_deprecated_authenticators(args)
      args.collect { |name|
        case name
        when :mock
          Deprecation.notify("The :mock authenticator is now the " <<
                             ":static authority.  Please update your configuration.",
                             "2.2")
          :static
        when :authenticate_only
          Deprecation.notify("The :authenticate_only authenticator is no longer " <<
                             "necessary.  To prevent the portal access check, " <<
                             "don't include a portal in the configuration.",
                             "2.2")
          nil
        else
          name
        end
      }.compact
    end

    def use_cas
      Deprecation.notify("use_cas is deprecated.  Use api_modes :cas_proxy; " <<
                         "ui_mode :cas; authorities :cas instead.",
                         "2.2")

      ui_mode :cas
      api_modes :cas_proxy
      authorities :cas
    end
  end

  ##
  # @private
  class Configurator
    include ConfiguratorLanguage
    include DeprecatedConfiguratorLanguage

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
