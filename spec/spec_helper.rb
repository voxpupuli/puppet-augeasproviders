require 'pathname'
dir = Pathname.new(__FILE__).parent
$LOAD_PATH.unshift(dir, File.join(dir, 'lib'), File.join(dir, '..', 'lib'))

require 'rubygems'

require 'simplecov'
unless RUBY_VERSION =~ /^1\.8/
  require 'coveralls'
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
end
SimpleCov.start do
  add_group "AugeasProviders Libs", "/lib/augeasproviders/"
  add_group "Puppet Types", "/lib/puppet/type/"
  add_group "Puppet Providers", "/lib/puppet/provider/"
  add_group "Augeas Spec Lib", "/spec/lib/"

  add_filter "/spec/fixtures/"
  add_filter "/spec/unit/"
  add_filter "/spec/support/"
end

require 'puppetlabs_spec_helper/module_spec_helper'
require 'augeas_spec'

Puppet[:modulepath] = File.join(dir, 'fixtures', 'modules')

# Load all shared contexts and shared examples
Dir["#{dir}/support/**/*.rb"].sort.each {|f| require f}
