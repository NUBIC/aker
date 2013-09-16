$LOAD_PATH << File.expand_path("lib", File.dirname(__FILE__))

require 'bundler/gem_tasks'

require 'rake'
require 'rspec/core/rake_task'
require 'cucumber/rake/task'
require 'yard'
require 'saikuro_treemap'
gem 'ci_reporter'
require 'ci/reporter/rake/rspec'

require 'aker'
require 'castanet/testing'
require 'uri'

Dir["tasks/*.rake"].each { |f| import f }

desc "Run all specs"
RSpec::Core::RakeTask.new('spec') do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.verbose = true
end

namespace :cucumber do
  desc "Run features that should pass"
  Cucumber::Rake::Task.new(:ok) do |t|
    t.fork = true
    t.profile = "default"
  end

  desc "Run features that are being worked on"
  Cucumber::Rake::Task.new(:wip) do |t|
    t.fork = true
    t.profile = "wip"
  end

  desc "Run features that are flagged as failing on the current platform"
  Cucumber::Rake::Task.new(:wip_platform) do |t|
    t.fork = true
    t.profile = "wip_platform"
  end

  desc "Run all features"
  task :all => [:ok, :wip, :wip_platform]
end

namespace :metrics do
  desc 'generate ccn treemap'
  task :complexity_map do
    if RUBY_PLATFORM != 'java' && RUBY_VERSION !~ /1.9/
      f = "reports/complexity_map.html"
      SaikuroTreemap.generate_treemap :code_dirs => ['lib'], :output_file => f
      puts "Generated complexity map in #{f}"
    else
      puts "Only works on MRI 1.8"
    end
  end
end

task :yard => ['yard:auto']

namespace :yard do
  desc "Run a server which will rebuild documentation as the source changes"
  task :auto do
    system("bundle exec yard server --reload")
  end

  desc "Build API documentation with yard"
  YARD::Rake::YardocTask.new("once") do |t|
    t.options = ["--title", "Aker #{Aker::VERSION}"]
  end

  desc "Purge all YARD artifacts"
  task :clean do
    rm_rf 'doc'
    rm_rf '.yardoc'
  end
end

task :default => :spec

def trace?
  Rake.application.options.trace
end

task 'release' => ['deploy:check']

namespace :deploy do
  task :check do
    if Aker::VERSION.split('.').any? { |v| v =~ /\D/ }
      puts "#{Aker::VERSION} is a prerelease version.  Are you sure you want to deploy?\n" <<
        "Press ^C to abort or enter to continue deploying."
      STDIN.readline
    end
  end
end

namespace :ci do
  task :all => ['ci:setup:rspec', :spec, :cucumber]
  ENV["CI_REPORTS"] = "reports/spec-xml"

  Cucumber::Rake::Task.new(:cucumber, 'Run features using the ci profile') do |t|
    t.fork = true
    t.profile = 'ci'
  end

  Castanet::Testing::JasigServerTasks.new(
    :ssl_cert => File.expand_path('../features/support/integrated-test-ssl.crt', __FILE__),
    :ssl_key => File.expand_path('../features/support/integrated-test-ssl.key', __FILE__),
    :scratch_dir => File.expand_path('../tmp/aker-integrated-tests', __FILE__),
    :jasig_url => 'http://downloads.jasig.org/cas/cas-server-3.4.3-release.tar.gz',
    :jasig_checksum => 'b08a8972649f961ed3e0433d3cf936b11af4354fc00f45a0bc1327e8e5caf0cc'
  )

  Castanet::Testing::CallbackServerTasks.new(
    :ssl_cert => File.expand_path('../features/support/integrated-test-ssl.crt', __FILE__),
    :ssl_key => File.expand_path('../features/support/integrated-test-ssl.key', __FILE__),
    :scratch_dir => File.expand_path('../tmp/aker-integrated-tests', __FILE__)
  )

  desc 'Download daemons used for CI testing'
  task :download_daemons => :download_cas_daemons

  task :download_cas_daemons => ['ci:castanet:testing:jasig:download']

  desc 'Generate URLs for daemons used in CI testing'
  task :set_server_urls => [:set_cas_urls, :set_ladle_url]

  task :set_cas_urls do
    cas_base_url = `./ci_local_url https /cas`.chomp
    cas_callback_base_url = `./ci_local_url https / callback`.chomp

    puts %Q{
      export CAS_BASE_URL=#{cas_base_url}
      export CAS_PROXY_CALLBACK_URL=#{cas_callback_base_url}receive_pgt
      export CAS_PROXY_RETRIEVAL_URL=#{cas_callback_base_url}retrieve_pgt
    }
  end

  task :set_ladle_url do
    ladle_url = `./ci_local_url ldap /`.chomp

    puts %Q{
      export LADLE_URL=#{ladle_url}
    }
  end

  desc 'Start daemons used in CI testing'
  task :start_servers => :start_cas

  task :start_cas do
    cb_port = URI.parse(ENV['CAS_PROXY_CALLBACK_URL']).port.to_s
    cb_pid = Process.spawn({ 'PORT' => cb_port }, 'rake', 'ci:castanet:testing:callback:start', { :out => '/dev/null', :err => '/dev/null' })
    puts "Starting CAS proxy callback at #{ENV['CAS_PROXY_CALLBACK_URL']}, PID #{cb_pid}"

    cas_port = URI.parse(ENV['CAS_BASE_URL']).port.to_s
    cas_pid = Process.spawn({ 'PORT' => cas_port }, 'rake', 'ci:castanet:testing:jasig:start', { :out => '/dev/null', :err => '/dev/null' })
    puts "Starting CAS at #{ENV['CAS_BASE_URL']}, PID #{cas_pid}"

    cleanup = lambda do |*|
      [cb_pid, cas_pid].each do |pid|
        begin
          Process.kill('TERM', pid)
          puts "kill -TERM #{pid}"
        rescue Errno::ESRCH
          # see below
        end
      end
    end

    # Account for normal exits and abnormal, trappable exits.
    #
    # Trapping INT eliminates the "rake aborted!" error that Rake signals by
    # default.  Installing an at_exit hook is insurance.
    #
    # FYI, this is why we need the begin ... rescue construct in the cleanup
    # block -- we're going to end up trying to kill our children at least
    # twice.  (UNIX is a brutal world.)  There is a high probability that one
    # of the kills will fail with ESRCH.
    trap(:INT, &cleanup)
    at_exit(&cleanup)

    Process.waitall
  end
end

task :autobuild => :'ci:all'
