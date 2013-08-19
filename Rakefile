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
end
task :autobuild => :'ci:all'
