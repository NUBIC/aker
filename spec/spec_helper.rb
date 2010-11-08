require 'bundler'
Bundler.setup

require 'rspec'

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'bcsec'
require 'bcaudit'

require File.expand_path('../database_helper', __FILE__)
require File.expand_path('../deprecation_helper', __FILE__)
require File.expand_path('../logger_helper', __FILE__)
require File.expand_path("../../tool-patches/rcov-encoding-1.9.rb", __FILE__)

if RUBY_PLATFORM == 'java'
  require File.expand_path('../java_helper', __FILE__)
end

RSpec.configure do |config|
  Bcsec::Spec::DatabaseData.use_in(config)
  Bcsec::Spec::DeprecationMode.use_in(config)
  config.include Bcsec::Spec::LoggerHelper

  config.before do
    Bcaudit::AuditInfo.current_user = Bcsec::User.new("spec-runner").tap { |u| u.personnel_id = 42 }
  end
end

def port_offset
  case ENV["BCSEC_ENV"]
  when /jruby/
    108
  when /1.9.1/
    207
  else
    0
  end
end
