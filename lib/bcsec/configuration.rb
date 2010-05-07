require 'bcsec'

# can't do just core_ext/string in AS 2.3
require 'active_support/core_ext'

module Bcsec
  ##
  # The representation of a configuration for the bcsec system,
  # including authorities, application attributes, and authentication
  # modes.
  class Configuration
    ##
    # Creates a new configuration.  If a block is given, it will be
    # evaluated using the {ConfiguratorLanguage DSL} and appended to
    # the new instance.
    def initialize(&config)
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
    #   * A `Symbol` or a `String` will be camelized and then
    #     interpreted as a class name in {Bcsec::Authorities}.
    #     Then it will be treated as a `Class`.  E.g.,
    #     `:all_access` will be converted into
    #     `Bcsec::Authorities::AllAccess`.
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
      parameters_for(group).merge!(params)
    end

    ##
    # Loads parameters from the given bcsec central parameters
    # file.
    #
    # @param [String] filename the filename
    # @return [void]
    def central(filename)
      params = ::Bcsec::CentralParameters.new(filename)

      add_parameters_for(:netid, params[:netid])
      add_parameters_for(:pers, params[:cc_pers].dup.tap { |pers|
        pers[:activerecord][:username] = pers[:user]
        pers[:activerecord][:password] = pers[:password]
      })
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
        instantiate_authority(authority_class_for_name(spec))
      when String
        instantiate_authority(authority_class_for_name(spec))
      when Class
        instantiate_authority(spec)
      else # assume it's an instance
        spec
      end
    end

    def instantiate_authority(clazz)
      clazz.new(self)
    end

    def authority_class_for_name(name)
      Bcsec::Authorities.const_get(name.to_s.camelize)
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

    def rlogin_target(*args)
      Deprecation.notify("rlogin is no longer supported.", "2.0")
    end
    alias rlogin_handler rlogin_target

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
