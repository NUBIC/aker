disable_system_gems
if RUBY_PLATFORM == 'java'
  bin_path 'jgem_bin'
else
  bin_path 'gem_bin'
end

gem 'activesupport', '~> 2.3'

only :development do
  gem 'rspec', '~> 1.3'
  gem 'rcov', '~> 0.9'
  gem 'yard', '~> 0.5'
  # for yard; doesn't work in jruby
  gem 'bluecloth' unless RUBY_PLATFORM == 'java'

  gem 'net-ssh', '~> 2.0'
  gem 'net-scp', '~> 1.0'
  gem 'rake', '>= 0.8.7'
  gem 'ci_reporter', '~> 1.6'
  gem 'jruby-openssl' if RUBY_PLATFORM == 'java'
end
