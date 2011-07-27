require 'bundler'
Bundler.setup

require "rspec"
require "fileutils"

$LOAD_PATH.unshift File.expand_path("../../../lib", __FILE__)

require 'aker'
require 'rack'

require File.expand_path("../../../spec/matchers", __FILE__)
require File.expand_path("../controllable_cas_server.rb", __FILE__)
require File.expand_path("../mechanize_test.rb", __FILE__)

Before do
  # suppress logging
  aker_log = "#{tmpdir}/aker.log"
  Aker.configure {
    logger Logger.new(aker_log)
  }
end

Before('@cas') do
  start_cas_server
end

After do
  stop_spawned_servers
end

module Aker::Cucumber
  class World
    include ::Aker::Spec::Matchers
    include ::RSpec::Matchers
    include ::Aker::Cucumber::MechanizeTest
    include FileUtils

    CAS_PORT = 5409
    APP_PORT = 5004

    def app
      @app or fail "No main rack app created yet"
    end

    def enhance_configuration_from_table(cucumber_table, aker_configuration=nil)
      aker_configuration ||= (Aker.configuration ||= Aker::Configuration.new)
      string_conf = cucumber_table.hashes.first
      aker_configuration.enhance {
        string_conf.each_pair do |attr, value|
          value =
            case attr
            when /mode/
              value.split(' ')
            when /_parameters/
              eval(value).tap { |h|
                fail "#{value.inspect} did not eval to a Hash" unless h.is_a?(Hash)
              }
            else
              value
            end
          if value && !value.empty?
            value = [value] if value.is_a?(Hash)
            self.send(attr.to_sym, *value)
          end
        end
      }
    end

    def tmpdir
      @tmpdir ||= File.expand_path("../../..//tmp/aker-integrated-tests", __FILE__)
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
      base = case ENV["AKER_ENV"]
             when /jruby/
               17
             when /1.9/
               26
             when /1.8/
               31
             else
               0
             end
      case ENV["ACTIVESUPPORT_VERSION"]
      when /3.0/
        base * 5
      when /2.3/
        base * 7
      else
        base * 1
      end
    end

    def start_cas_server
      @cas_server = ControllableCasServer.new(tmpdir, CAS_PORT + port_offset)
      self.spawned_servers << @cas_server
      @cas_server.start
      @cas_server
    end

    # @return [Aker::Cucumber::ControllableRackServer]
    def start_rack_server(app, port, options={})
      opts = { :app => app, :port => port + port_offset, :tmpdir => tmpdir }.merge(options)
      new_server = Aker::Cucumber::ControllableRackServer.new(opts)
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

    def restart_spawned_servers
      stop_spawned_servers

      spawned_servers.each { |server| server.start }
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
  Aker::Cucumber::World.new
end
