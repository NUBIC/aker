require 'bundler'
Bundler.setup

require "rspec"
require "fileutils"
require "timeout"

$LOAD_PATH.unshift File.expand_path("../../../lib", __FILE__)

require 'aker'
require 'rack'
require 'ladle'
require 'uri'

require File.expand_path("../../../spec/matchers", __FILE__)
require File.expand_path("../mechanize_test.rb", __FILE__)

Before do
  # suppress logging
  aker_log = "#{tmpdir}/aker.log"
  Aker.configure {
    logger Logger.new(aker_log)
  }
  ar_log = "#{tmpdir}/active_record.log"
end

Before('@cas') do
  check_cas_server
end

Before('@ldap') do
  start_ladle_server
end

After do
  stop_spawned_servers
  stop_ladle_server
end

module Aker::Cucumber
  class World
    include ::Aker::Spec::Matchers
    include ::RSpec::Matchers
    include ::Aker::Cucumber::MechanizeTest
    include FileUtils

    def initialize
      # Create LDAP server once; only start it when necessary
      @ladle_server = Ladle::Server.new(
        :quiet => true,
        :port => URI.parse(ladle_url).port,
        :timeout => ENV['CI_RUBY'] ? 90 : 15 # the CI server is slow sometimes
      )
    end

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

    %w(cas_base_url cas_proxy_retrieval_url cas_proxy_callback_url ladle_url).each do |m|
      class_eval <<-END
        def #{m}
          ENV['#{m.upcase}'] or raise '#{m.upcase} is not set'
        end
      END
    end

    def check_cas_server
      [
        ['CAS server URL', cas_base_url],
        ['CAS proxy retrieval URL', cas_proxy_retrieval_url],
        ['CAS proxy callback URL', cas_proxy_callback_url]
      ].each do |url_kind, url|
        expect_2xx url, true
      end
    end

    def expect_2xx(url, use_ssl, timeout = 90)
      Timeout::timeout(timeout) do
        uri = URI(url)
        h = Net::HTTP.new(uri.host, uri.port)
        h.use_ssl = use_ssl
        req = Net::HTTP::Get.new(uri.path)

        loop do
          begin
            resp = h.request(req)

            break if resp.code.to_i < 500
          rescue => e
            puts "Connect to #{url} failed: #{e.class} (#{e.message}); retrying in 1 sec"
            sleep 1
          end
        end
      end
    end

    # @return [Aker::Cucumber::ControllableRackServer]
    def start_rack_server(app, name, options={})
      scheme = options[:ssl] ? 'https' : 'http'
      url = `./ci_local_url #{scheme} / #{name}`.chomp

      opts = { :app => app, :url => url, :tmpdir => tmpdir }.merge(options)
      new_server = Aker::Cucumber::ControllableRackServer.new(opts)
      self.spawned_servers << new_server
      new_server.start
      new_server
    end

    def start_main_rack_server(app, options={})
      @app = app
      @app_server = start_rack_server(app, 'main', options)
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

    def start_ladle_server
      @ladle_server.start
    end

    def stop_ladle_server
      @ladle_server.stop if @ladle_server
    end

    def app_url(url)
      if url =~ /^http/
        url
      else
        "http://#{@app_server.host}:#{@app_server.port}#{url}"
      end
    end
  end
end

World do
  Aker::Cucumber::World.new
end
