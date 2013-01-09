source :rubygems

if ENV.key?('PUPPET_VERSION')
  puppetversion = "~> #{ENV['PUPPET_VERSION']}"
else
  puppetversion = ['>= 0.25']
end

gem 'librarian-puppet'
gem 'puppet', puppetversion
gem 'ruby-augeas', '>= 0.3.0'

group :development do
  gem 'puppet-lint'
  gem 'puppetlabs_spec_helper', '>= 0.4.1'
  gem 'rake'
  gem 'rspec-puppet'
  gem 'simplecov'
end
