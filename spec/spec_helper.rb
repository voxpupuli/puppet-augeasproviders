require 'pathname'
dir = Pathname.new(__FILE__).parent
$LOAD_PATH.unshift(dir, File.join(dir, 'lib'), File.join(dir, '..', 'lib'))

require 'rubygems'

require 'simplecov'
SimpleCov.start do
  add_filter "/spec/fixtures/modules/mount_providers/"
  add_filter { |src_file|
    # gets loaded via spec/fixtures/modules/ap/lib
    src_file.filename.end_with?("/lib/augeasproviders/provider.rb") and not src_file.filename =~ /fixtures/
  }
  add_filter "/spec/lib/"
  add_filter "/spec/unit/"
end

require 'puppetlabs_spec_helper/module_spec_helper'
require 'augeas_spec'

Puppet[:modulepath] = File.join(dir, 'fixtures', 'modules')

# Load all shared contexts and shared examples
Dir["#{dir}/support/**/*.rb"].sort.each {|f| require f}

require 'coveralls'
Coveralls.wear!
