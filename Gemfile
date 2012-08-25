source :rubygems

if ENV.key?('PUPPET_VERSION')
  puppetversion = "= #{ENV['PUPPET_VERSION']}"
else
  puppetversion = ['>= 2.7']
end

gem 'ruby-augeas', '>= 0.3.0'
gem 'librarian-puppet'

group :development do
  gem 'puppet', puppetversion
  gem 'puppet-lint'
  gem 'puppetlabs_spec_helper', '>= 0.2.0'
  gem 'rake'
  gem 'rspec-puppet'
  gem 'simplecov'
end
