require File.expand_path("../../vendor/gems/environment", __FILE__)

require "spec"
require 'spec/test/unit'

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'bcsec'

require File.expand_path('../database_helper', __FILE__)
require File.expand_path('../deprecation_helper', __FILE__)

Spec::Runner.configure do |config|
  Bcsec::Spec::DatabaseData.use_in(config)
  Bcsec::Spec::DeprecationMode.use_in(config)
end
