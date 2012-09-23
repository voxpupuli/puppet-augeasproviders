require 'pathname'
dir = Pathname.new(__FILE__).parent
$LOAD_PATH.unshift(dir, File.join(dir, 'lib'), File.join(dir, '..', 'lib'))

require 'rubygems'

require 'simplecov'
SimpleCov.start do
  add_filter "/modules/"
  add_filter "/spec/"
end

require 'puppetlabs_spec_helper/module_spec_helper'
require 'augeas_spec'

RSpec.configure do |config|
  config.mock_with :mocha
end

Puppet[:modulepath] = File.join(dir, '..', 'modules')

# Workaround for issue #16277 where default settings aren't initialised from a
# spec and so the libdir is never initialised
if Puppet.settings.respond_to? :app_defaults_initialized?
  Puppet[:libdir] = Dir["#{Puppet[:modulepath]}/*/lib"].entries.join(File::PATH_SEPARATOR)
end

