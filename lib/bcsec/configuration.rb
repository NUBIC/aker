require 'bcsec'

# can't do just core_ext/string in AS 2.3
require 'active_support/core_ext'

module Bcsec
  class Configuration
    def initialize(&config)
      self.enhance(&config) if config
    end

    def enhance(&additional_config)
      Configurator.new(self, &additional_config)
      self
    end

    def ui_mode
      @ui_mode ||= :form
    end

    def ui_mode=(ui_mode)
      @ui_mode = nil_or_sym(ui_mode)
    end

    def api_modes
      @api_modes ||= []
    end

    def api_modes=(*new_modes)
      new_modes = new_modes.first if new_modes.size == 1 && Array === new_modes.first
      @api_modes = new_modes.collect { |m| nil_or_sym(m) }
    end
    alias api_mode= api_modes=

    def portal
      raise "No portal configured" unless @portal
      @portal
    end

    def portal=(portal)
      @portal = nil_or_sym(portal)
    end

    def authorities
      raise "No authorities configured" if @authorities.nil? || @authorities.empty?
      @authorities
    end

    def authorities=(new_authorities)
      @authorities = new_authorities.collect { |a| build_authority(a) }
    end

    def parameters_for(group)
      @parameter_groups ||= { }
      @parameter_groups[group] ||= { }
    end

    def add_parameters_for(group, params)
      parameters_for(group).merge!(params)
    end

    def central(filename)
      params = ::Bcsec::CentralParameters.new(filename)

      add_parameters_for(:netid, params[:netid])
      add_parameters_for(:pers, params[:cc_pers].dup.tap { |pers|
        pers[:activerecord][:username] = pers[:user]
        pers[:activerecord][:password] = pers[:password]
      })
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

  module ConfiguratorLanguage
    def authorities(*authorities)
      @specified_authorities = authorities
    end
    alias authority authorities

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

    def deferred_setup
      @config.authorities = @specified_authorities if @specified_authorities
    end
  end

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
        new_name = case name
                   when :authenticate_only; :all_access;
                   when :mock; :static;
                   end
        if new_name
          Deprecation.notify("The #{name.inspect} authenticator is now the " <<
                             "#{new_name.inspect} authority.  Please update your configuration.",
                             "2.2")
          new_name
        else
          name
        end
      }
    end
  end

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
