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

# There's no real need to make this version dependent, but it helps find
# regressions in Puppet
#
# 1. Workaround for issue #16277 where default settings aren't initialised from
# a spec and so the libdir is never initialised (3.0.x)
# 2. Workaround for 2.7.20 that now only loads types for the current node
# environment (#13858) so Puppet[:modulepath] seems to get ignored
#
ver = Gem::Version.new(Puppet.version.split('-').first)
if Gem::Requirement.new("~> 2.7.20") =~ ver || Gem::Requirement.new("~> 3.0.0") =~ ver
  puts "augeasproviders: setting Puppet[:libdir] to work around broken type autoloading"
  # libdir is only a single dir, so it can only workaround loading of one external module
  Puppet[:libdir] = "#{Puppet[:modulepath]}/mount_providers/lib"
end

