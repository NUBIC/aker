require 'rack/builder'
require 'yaml'
require 'picnic/conf'
require 'fileutils'
require 'sqlite3'
require File.expand_path('../spawned_http_server.rb', __FILE__)

# Because rubycas-server's config.ru refers to the Rack module, it
# needs to be interpreted outside of the Bcsec module.
module CASServer
  def self.app(config_filename)
    $CONF = Picnic::Conf.new
    $CONF.load_from_file(nil, nil, config_filename)

    rackup = File.expand_path("../config.ru",
                              $LOAD_PATH.detect { |path| path =~ /rubycas-server/ })
    app = ::Rack::Builder.new.instance_eval(File.read(rackup))
  end
end

module Bcsec
  module Cucumber
    class ControllableCasServer < SpawnedHttpServer
      include FileUtils

      attr_reader :tmpdir, :users_database_filename

      def initialize(tmpdir, port)
        super(:port => port)
        @tmpdir = tmpdir
      end

      def start
        @users_database_filename = create_user_database
        super
      end

      def exec_server
        Signal.trap("TERM") {
          $stdout.flush
          $stderr.flush
          exit!(0)
        }

        $stdout = File.open("#{tmpdir}/cas-out.log", "w")
        $stderr = $stdout

        app = CASServer.app(create_server_config(binding))
        ::Rack::Handler::WEBrick.run app, :Port => port
      end

      def stop
        @db.close if @db
        super
      end

      def register_user(username, password)
        @db.execute("INSERT INTO users (username, password) VALUES (?, ?)",
                    username, password)
      end

      private

      def create_user_database
        File.join(tmpdir, 'cas-users.db').tap do |fn|
          rm fn if File.exist?(fn)
          @db = SQLite3::Database.new(fn)
          @db.execute("CREATE TABLE users (username, password)")
        end
      end

      def create_server_config(scope)
        File.join(tmpdir, 'cas-config.yml').tap do |fn|
          File.open(fn, 'w') do |f|
            f.write(ERB.new(File.read(File.expand_path("../casserver.yml.erb", __FILE__))).
              result(scope))
          end
        end
      end
    end
  end
end
