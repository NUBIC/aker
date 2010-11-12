require 'bundler'
Bundler.setup

require "rspec"
require "fileutils"

$LOAD_PATH.unshift File.expand_path("../../../lib", __FILE__)

require 'bcsec'
require 'rack'

require File.expand_path("../../../spec/matchers", __FILE__)
require File.expand_path("../controllable_cas_server.rb", __FILE__)
require File.expand_path("../mechanize_test.rb", __FILE__)

Before do
  # suppress logging
  bcsec_log = "#{tmpdir}/bcsec.log"
  Bcsec.configure {
    logger Logger.new(bcsec_log)
  }
end

Before('@cas') do
  start_cas_server
end

After do
  stop_spawned_servers
end

module Bcsec::Cucumber
  class World
    include ::Bcsec::Spec::Matchers
    include ::RSpec::Matchers
    include ::Bcsec::Cucumber::MechanizeTest
    include FileUtils

    CAS_PORT = 5409
    APP_PORT = 5004

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

    def port_offset
      case ENV['BCSEC_ENV']
      when /1.8.7/; 1008;
      when /1.9/;   2007;
      else 0;
      end
    end

    def start_cas_server
      @cas_server = ControllableCasServer.new(tmpdir, CAS_PORT + port_offset)
      self.spawned_servers << @cas_server
      @cas_server.start
      @cas_server
    end

    # @return [Bcsec::Cucumber::ControllableRackServer]
    def start_rack_server(app, port, options={})
      opts = { :app => app, :port => port + port_offset, :tmpdir => tmpdir }.merge(options)
      new_server = Bcsec::Cucumber::ControllableRackServer.new(opts)
      self.spawned_servers << new_server
      new_server.start
      new_server
    end

    def start_main_rack_server(app, options={})
      @app = app
      start_rack_server(app, APP_PORT, options)
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

    def app_url(url)
      if url =~ /^http/
        url
      else
        "http://localhost:#{APP_PORT + port_offset}#{url}"
      end
    end
  end
end

World do
  Bcsec::Cucumber::World.new
end
