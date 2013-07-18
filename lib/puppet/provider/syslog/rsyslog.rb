# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2012 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Puppet::Type.type(:syslog).provide(:rsyslog, :parent => :augeas) do
  desc "Uses Augeas API to update an rsyslog.conf entry"

  default_file { '/etc/rsyslog.conf' }
  lens { 'Rsyslog.lns' }

  resource_path do |resource|
    entry_path(resource)
  end

  confine :feature => :augeas
  confine :exists => target
end
