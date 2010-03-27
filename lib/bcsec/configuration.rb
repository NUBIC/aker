require 'bcsec'
require 'bcsec/authorities'

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

    def api_modes=(new_modes)
      @api_modes = (new_modes || []).collect { |m| nil_or_sym(m) }
    end
    
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
      else # assume its an instance
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

  class Configurator
    def initialize(target, &block)
      @config = target
      evaluate(&block)
    end

    def portal(portal)
      @config.portal = portal
    end

    def ui_mode(mode)
      @config.ui_mode = mode
    end

    def api_modes(*modes)
      @config.api_modes = modes
    end
    alias api_mode api_modes

    def authorities(*authorities)
      @specified_authorities = authorities
    end
    alias authority authorities

    private
    
    def evaluate(&block)
      instance_eval(&block)
      @config.authorities = @specified_authorities if @specified_authorities
    end
  end
end
