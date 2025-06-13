# Managed by modulesync - DO NOT EDIT
# https://voxpupuli.org/docs/updating-files-managed-with-modulesync/

# Attempt to load voxpupuli-test (which pulls in puppetlabs_spec_helper),
# otherwise attempt to load it directly.
begin
  require 'voxpupuli/test/rake'
rescue LoadError
  begin
    require 'puppetlabs_spec_helper/rake_tasks'
  rescue LoadError
  end
end

# load optional tasks for acceptance
# only available if gem group releases is installed
begin
  require 'voxpupuli/acceptance/rake'
rescue LoadError
end

# load optional tasks for releases
# only available if gem group releases is installed
begin
  require 'voxpupuli/release/rake_tasks'
rescue LoadError
  # voxpupuli-release not present
else
  GCGConfig.user = 'voxpupuli'
  GCGConfig.project = 'puppet-augeasproviders'
end


# vim: syntax=ruby
