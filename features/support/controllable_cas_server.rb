require 'fileutils'
require 'sqlite3'
require File.expand_path('../spawned_http_server.rb', __FILE__)

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
        config_filename = create_server_config(binding)
        exec("gem_bin/rubycas-server -c '#{config_filename}'")
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
