$LOAD_PATH << File.expand_path("lib", File.dirname(__FILE__))

require 'bundler'
Bundler.setup

require 'rake'
require 'rake/gempackagetask'
require 'rspec/core/rake_task'
require 'cucumber/rake/task'
require 'yard'
require 'bcdatabase/oracle/tasks'
require 'saikuro_treemap'
require 'net/ssh'
require 'net/scp'
gem 'ci_reporter'
require 'ci/reporter/rake/rspec'

require 'bcsec'

gemspec = eval(File.read('bcsec.gemspec'), binding, 'bcsec.gemspec')

Rake::GemPackageTask.new(gemspec).define

GEM_FILE = "pkg/#{gemspec.file_name}"

desc "Run all specs"
RSpec::Core::RakeTask.new('spec') do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.verbose = true
end

desc "Run all specs with rcov"
RSpec::Core::RakeTask.new('spec:rcov') do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rcov = true
  # rcov can't tell that /Library/Ruby & .rvm are system paths
  t.rcov_opts = ['--exclude', "spec/*,/Library/Ruby/*,#{ENV['HOME']}/.rvm"]
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
    t.options = ["--title", "bcsec #{Bcsec::VERSION}"]
  end

  desc "Create API documentation combined with bcsec-rails"
  task "with-rails" do
    # Need to defer determining the path to bcsec-rails until it is
    # actually used, so we can't use YardocTask at the top level
    YARD::Rake::YardocTask.new("with-rails-actual") do |t|
      t.options = %w(--db .yardoc-with-rails -o doc-with-rails) +
        ["--title", "bcsec #{Bcsec::VERSION} & bcsec-rails"]
      bcsec_rails_path =
        ENV['BCSEC_RAILS_PATH'] || "../bcsec-rails"
      raise "Please specify BCSEC_RAILS_PATH" unless File.directory?(bcsec_rails_path)
      t.files =
        ["lib/**/*.rb", "#{bcsec_rails_path}/lib/**/*.rb"] +
        %w(-) +
        Dir.glob("#{File.expand_path(bcsec_rails_path)}/{README,CHANGELOG,MIGRATION}-rails")
    end
    task('with-rails-actual').invoke
  end

  desc "Purge all YARD artifacts"
  task :clean do
    rm_rf 'doc'
    rm_rf '.yardoc'
    rm_rf 'doc-with-rails'
    rm_rf '.yardoc-with-rails'
  end
end

task :default => :spec

desc "Reinstall the current development gem"
task :install => [:repackage, :uninstall] do
  puts "Installing new snapshot of #{gemspec.name}-#{gemspec.version}"
  puts `gem install #{GEM_FILE}`
end

desc "Uninstall the current development gem (if any)"
task :uninstall do
  puts "Removing existing #{gemspec.name}-#{gemspec.version}, if any"
  puts `gem uninstall #{gemspec.name} --version '=#{gemspec.version}'`
end

desc "Deploy to the internal gem server"
task :deploy => :"deploy:gem"

def trace?
  Rake.application.options.trace
end

def one_ssh_cmd(ssh, cmd)
  $stderr.puts "\n-> #{cmd}" if trace?
  ssh.exec(cmd)
  ssh.loop
end

namespace :deploy do
  task :check do
    if Bcsec::VERSION.split('.').any? { |v| v =~ /\D/ }
      puts "#{Bcsec::VERSION} is a prerelease version.  Are you sure you want to deploy?\n" <<
        "Press ^C to abort or enter to continue deploying."
      STDIN.readline
    end
  end

  task :gem => [:check, :repackage] do
    server = "ligand"
    user = ENV["BC_USER"] or raise "Please set BC_USER=your_netid in the environment"
    target = File.basename(GEM_FILE)
    Net::SSH.start(server, user) do |ssh|
      puts "-> Uploading #{GEM_FILE}"
      channel = ssh.scp.upload(GEM_FILE, "/home/#{user}") do |ch, name, sent, total|
        puts sent == total ? "  complete" : "  #{sent}/#{total}"
      end
      channel.wait

      one_ssh_cmd(ssh, "deploy-gem #{target}")
    end
  end

  desc "Tag the final version of a release"
  task :tag => [:check] do
    tagname = Bcsec::VERSION
    system("git tag -a #{tagname} -m 'Bcsec #{Bcsec::VERSION}'")
    fail "Tagging failed" unless $? == 0
    system("git push origin : #{tagname}")
  end

  task :docs => [:"yard:with-rails"] do
    server = "ligand"
    user = ENV["BC_USER"] or raise "Please set BC_USER=your_netid in the environment"
    server_dir = "/var/www/sites/download/docs/bcsec"
    Net::SSH.start(server, user) do |ssh|
      puts "-> Removing old docs"
      one_ssh_cmd(ssh, "rm -r #{server_dir}")

      puts "-> Uploading docs"
      channel = ssh.scp.upload(
        "doc-with-rails", server_dir, :recursive => true) do |ch, name, sent, total|
        print '.'
        $stdout.flush
      end
      channel.wait
      print "\n"
    end
  end
end

if ENV['ORACLE_HOME']
  Bcdatabase::Oracle.create_users_task(["cc_pers_test"])
  desc "Import the cc_pers_test dump (requires imp)"
  Bcdatabase::Oracle.import_task(
    "test:db:import",
    :local_oracle,
    :local_oracle,
    :cc_pers_test,
    :filename => "db/exports/cc_pers_test.dmp"
    )
  Bcdatabase::Oracle.wipe_task(
    "test:db:wipe",
    :local_oracle,
    :cc_pers_test
    )
  task "test:db:import" => "test:db:wipe"
else
  $stderr.puts "Not defining bcoracle tasks because ORACLE_HOME is not set."
end

namespace :ci do
  task :all => [:spec, :cucumber]

  ENV["CI_REPORTS"] = "reports/spec-xml"
  task :spec => ["ci:setup:rspec", 'spec:rcov']

  Cucumber::Rake::Task.new(:cucumber, 'Run features using the ci profile') do |t|
    t.fork = true
    t.profile = 'ci'
  end
end
task :autobuild => :'ci:all'
