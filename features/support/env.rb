require File.expand_path("../../../vendor/gems/environment", __FILE__)

require "spec"
require "fileutils"

$LOAD_PATH.unshift File.expand_path("../../../lib", __FILE__)

require 'bcsec'

require 'capybara'
require 'capybara/cucumber'
require 'rack/test'

require File.expand_path("../controllable_cas_server.rb", __FILE__)

Before do
  # suppress logging
  Bcsec.configure {
    logger Logger.new(StringIO.new)
  }
end

Before('@cas') do
  Capybara.current_driver = :culerity
  start_cas_server
end

After('@cas') do
  Capybara.use_default_driver
end

After do
  stop_spawned_servers
end

module Bcsec::Cucumber
  class World
    include Rack::Test::Methods
    include Spec::Matchers
    include FileUtils

    CAS_PORT = 5409

    def app
      @app or fail "No main rack app created yet"
    end

    def enhance_configuration_from_table(cucumber_table, bcsec_configuration=nil)
      bcsec_configuration ||= (Bcsec.configuration ||= Bcsec::Configuration.new)
      string_conf = cucumber_table.hashes.first
      bcsec_configuration.enhance {
        string_conf.each_pair do |attr, value|
          value =
            case attr
            when /mode/
              value.split(' ')
            else
              value
            end
          if value && !value.empty?
            self.send(attr.to_sym, *value)
          end
        end
      }
    end

    def tmpdir
      @tmpdir ||= "/tmp/bcsec-integrated-tests"
      unless File.exist?(@tmpdir)
        mkdir_p @tmpdir
        puts "Using tmpdir #{@tmpdir}"
      end
      @tmpdir
    end

    def spawned_servers
      @spawned_servers ||= []
    end

    def start_cas_server
      @cas_server = ControllableCasServer.new(tmpdir, CAS_PORT)
      self.spawned_servers << @cas_server
      @cas_server.start
      @cas_server
    end

    # @return [Bcsec::Cucumber::ControllableRackServer]
    def start_rack_server(app, port, options={})
      opts = { :app => app, :port => port, :tmpdir => tmpdir }.merge(options)
      new_server = Bcsec::Cucumber::ControllableRackServer.new(opts)
      self.spawned_servers << new_server
      new_server.start
      new_server
    end

    def stop_spawned_servers
      spawned_servers.each do |server|
        begin
          server.stop
        rescue => m
          $stderr.puts "Stopping server pid=#{server.pid} port=#{server.port} failed: #{m}"
        end
      end
    end
  end
end

World do
  Bcsec::Cucumber::World.new
end
