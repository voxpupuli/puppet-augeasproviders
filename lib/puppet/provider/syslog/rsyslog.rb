# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2012 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Puppet::Type.type(:syslog).provide(:rsyslog, :parent => :augeas) do
  desc "Uses Augeas API to update an rsyslog.conf entry"

  def self.file(resource = nil)
    file = "/etc/rsyslog.conf"
    file = resource[:target] if resource and resource[:target]
    file.chomp("/")
  end

  confine :feature => :augeas
  confine :exists => file

  def self.augopen(resource = nil)
    lens = "Rsyslog.lns"
    lens = resource[:lens] if resource and resource[:lens]
    AugeasProviders::Provider.augopen(lens, file(resource))
  end
end
