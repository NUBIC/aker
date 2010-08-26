$LOAD_PATH << File.expand_path("lib", File.dirname(__FILE__))

require 'vendor/gems/environment'

require 'rake'
require 'rake/gempackagetask'
require 'spec/rake/spectask'
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
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.verbose = true
end

desc "Run all specs with rcov"
Spec::Rake::SpecTask.new('spec:rcov') do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.rcov = true
  # rcov can't tell that /Library/Ruby is a system path
  t.rcov_opts = ['--exclude', "spec/*,/Library/Ruby/*"]
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

desc "Build API documentation with yard"
docsrc = %w(lib/**/*.rb)
docfiles = Dir.glob("{CHANGELOG}") # README is automatically included
YARD::Rake::YardocTask.new("yard") do |t|
  t.options = %w(--no-private --markup markdown --hide-void-return)
  t.options += ["--title", "bcsec #{Bcsec::VERSION}"]
  t.files = docsrc + ['-'] + docfiles
end

namespace :yard do
  desc "Rebuild API documentation after each change to the source"
  task :auto => :yard do
    require 'fssm'
    puts "Waiting for changes"
    FSSM.monitor('.', docsrc + docfiles + %w(README Rakefile)) do
      # have to run in a subshell because rake will only invoke a
      # given task once per execution
      yardoc = proc { |b, m|
        print "Detected change in #{m} -- regenerating docs ... "
        out = `rake yard`
        puts out if out =~ /warn|error/
        puts "done"
      }

      create &yardoc
      update &yardoc
      delete &yardoc
    end
  end

  desc "Create API documentation combined with bcsec-rails"
  task "with-rails" do
    # Need to defer determining the path to bcsec-rails until it is
    # actually used, so we can't use YardocTask at the top level
    YARD::Rake::YardocTask.new("with-rails-actual") do |t|
      t.options = %w(--no-private --markup markdown --hide-void-return) +
        %w(--db .yardoc-with-rails -o doc-with-rails) +
        ["--title", "bcsec #{Bcsec::VERSION} & bcsec-rails"]
      bcsec_rails_path =
        ENV['BCSEC_RAILS_PATH'] || "../bcsec-rails"
      raise "Please specify BCSEC_RAILS_PATH" unless File.directory?(bcsec_rails_path)
      t.files = docsrc +
        ["#{bcsec_rails_path}/lib/**/*.rb"] +
        %w(-) +
        docfiles +
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
    if Bcsec::VERSION.split('.').any? { |v| v =~ /\w/ }
      puts "#{Bcsec::VERSION} is a prerelease version.  Are you sure you want to deploy?\n" <<
        "Press ^C to abort or enter to continue deploying."
      STDIN.readline
    end
  end

  task :gem => [:check, :repackage] do
    raise "Don't deploy prerelease gems.  Set to a release version first." if Bcsec::VERSION =~ /pre/
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
