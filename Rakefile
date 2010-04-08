$LOAD_PATH << File.expand_path("lib", File.dirname(__FILE__))

require 'vendor/gems/environment'

require 'rake'
require 'rake/gempackagetask'
require 'spec/rake/spectask'
require 'yard'

require 'net/ssh'
require 'net/scp'
gem 'ci_reporter'
require 'ci/reporter/rake/rspec'

require 'bcsec'

# Evaluates a gemfile and appends the deps to a gemspec
class GemfileGemspecDeps
  def initialize(gemspec)
    @spec = gemspec
    instance_eval(File.read('Gemfile'))
  end

  def gem(name, version=[], *ignored)
    if @only && @only.include?(:development)
      @spec.add_development_dependency(name, *version)
    else
      @spec.add_runtime_dependency(name, *version)
    end
  end

  def only(*envs)
    @only = envs
    yield
    @only = nil
  end

  def method_missing(msg, *args)
    # do nothing for unimplemented bits
  end
end

gemspec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = "Bioinformatics core security infrastructure library"
  s.name = 'bcsec'
  s.version = File.read("VERSION").strip

  GemfileGemspecDeps.new(s)

  s.require_path = 'lib'
  s.bindir = 'bin'
  s.files = Dir.glob("{CHANGELOG,README,VERSION,{lib,spec}/**/*}")
  s.author = "Rhett Sutphin"
  s.email = "r-sutphin@northwestern.edu"
  s.homepage = "http://bcwiki.bioinformatics.northwestern.edu/bcwiki/index.php/Bcsec"
end

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

desc "Build API documentation with yard"
YARD::Rake::YardocTask.new do |t|
  t.options = %w(--no-private --markup markdown)
  t.files = %w(lib/**/*.rb -) + Dir.glob("{CHANGELOG,README}")
end

task :default => :spec

desc "Reinstall the current development gem"
task :install => [:repackage, :uninstall] do
  puts "Installing new snapshot of #{gemspec.name}-#{gemspec.version}"
  puts `sudo gem install #{GEM_FILE}`
end

desc "Uninstall the current development gem (if any)"
task :uninstall do
  puts "Removing existing #{gemspec.name}-#{gemspec.version}, if any"
  puts `sudo gem uninstall #{gemspec.name} --version '=#{gemspec.version}'`
end

desc "Regenerate the local gemspec (used for bundler's :path option)"
task :gemspec do
  puts "Regenerating gemspec"
  File.open('bcsec.gemspec', 'w') do |f|
    f.write gemspec.to_ruby
  end
end

desc "Deploy to the internal gem server"
task :deploy => [:repackage] do
  raise "Don't deploy prerelease gems.  Set to a release version first." if Bcsec::VERSION =~ /pre/
  dir = "/var/www/sites/download/gems"
  server = "ligand"
  group = "gemauthors"
  user = ENV["BC_USER"] or raise "Please set BC_USER=your_netid in the environment"
  Net::SSH.start(server, user) do |ssh|
    puts "-> Uploading #{GEM_FILE}"
    channel = ssh.scp.upload(GEM_FILE, "#{dir}/gems") do |ch, name, sent, total|
      puts sent == total ? "  complete" : "  #{sent}/#{total}"
    end
    channel.wait

    one_ssh_cmd(ssh, "gem generate_index --directory #{dir}")
    # chmod all new files to group-writable so that other people can deploy
    find_cmd = ["find #{dir} -user #{user}", ("-fprint /dev/stderr -print" if trace?)].compact.join(' ')
    one_ssh_cmd(ssh, "#{find_cmd} | xargs chgrp #{group}")
    one_ssh_cmd(ssh, "#{find_cmd} | xargs chmod g+w")
  end
end

def trace?
  Rake.application.options.trace
end

def one_ssh_cmd(ssh, cmd)
  $stderr.puts "\n-> #{cmd}" if trace?
  ssh.exec(cmd)
  ssh.loop
end

# Determines if the current checkout is using git-svn or just svn
def svn?
  Dir['**/.svn'].size > 0
end

namespace :deploy do
  desc "Tag the final version of a release"
  task :tag do
    raise "Don't deploy prerelease gems.  Set to a release version first." if Bcsec::VERSION =~ /pre/
    trunk_url = svn? ? `svn info`.match(/URL:\s+(.*?)\n/)[1] : `git svn info --url`.sub(/\/?\s*$/, '/gem')
    fail "Could not determine trunk URL" unless trunk_url
    fail "deploy:tag only works from the trunk" unless trunk_url =~ /trunk\/gem$/
    tag_url = trunk_url.gsub(/trunk\/gem$/, "tags/gem/#{Bcsec::VERSION}").chomp
    `svn ls #{tag_url} 2> /dev/null`
    if $? == 0
      puts "Tag #{tag_url} already exists"
    else
      puts "Creating #{tag_url}"
      puts `svn cp #{trunk_url} #{tag_url} -m 'Tag #{Bcsec::VERSION} release'`
    end
  end
end

task :autobuild => ['ci:setup:rspec', 'spec:rcov']
