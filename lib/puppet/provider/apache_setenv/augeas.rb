# Manages SetEnv entries in a Apache config
#
# Copyright (c) 2013 Endre Karlson
# Licensed under the Apache License, Version 2.0

require 'puppet'
require File.dirname(__FILE__) + '/../../../augeasproviders/provider'


Puppet::Type.type(:apache_setenv).provide(:augeas) do
  desc "Use Augeas API to update SetEnv in Apache"

  include AugeasProviders::Provider

  def self.file(resource = nil)
    file = "/etc/apache2/apache.conf"
    file = resource[:target] if resource and resource[:target]
    file.chomp("/")
  end

  confine :feature => :augeas
  confine :exists => file

  def self.augopen(resource = nil)
    AugrasProviders::Provider.augopen("ApacheSetEnv.lns", file(resource))
  end

  def self.instances
    aug = nil
    path = "/files#{file}"
    begin
      resources = []
      aug = augopen
      aug.match("#{path}/*") do |spath|
        resource = {:ensure => :present}

        basename = spath.split("/")[-1]
      end
    ensure
      aug.close if aug
    end
  end

  def exists?
    aug = nil
  end
end
