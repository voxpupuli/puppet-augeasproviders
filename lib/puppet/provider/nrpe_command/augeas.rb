# Alternative Augeas-based provider for nrpe type
#
# Copyright (c) 2012 Christian Kaenzig
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Puppet::Type.type(:nrpe_command).provide(:augeas) do
  desc "Uses Augeas API to update nrpe commands"

  include AugeasProviders::Provider

  default_file { '/etc/nagios/nrpe.cfg' }

  lens { 'Nrpe.lns' }

  confine :feature => :augeas

  def self.instances
    augopen do |aug, path|
      resources = []
      aug.match("/files#{target}/command/*").each do |spath|
        resource = {:ensure => :present}

        resource[:name] = spath.split("/")[-1]
        resource[:command] = aug.get("#{spath}")

        resources << new(resource)
      end
      resources
    end
  end

  def exists? 
    self.class.augopen(resource) do |aug, path|
      not aug.match("/files#{self.class.target(resource)}/command/#{resource[:name]}").empty?
    end
  end

  def create 
    self.class.augopen(resource) do |aug, path|
      aug.set("/files#{self.class.target(resource)}/command[last()+1]/#{resource[:name]}", resource[:command])
      augsave!(aug)
    end
  end

  def destroy
    self.class.augopen(resource) do |aug, path|
      aug.rm("/files#{self.class.target(resource)}/command[#{resource[:name]}]")
      augsave!(aug)
    end
  end

  def target
    self.class.target(resource)
  end

  def command
    self.class.augopen(resource) do |aug, path|
      aug.get("/files#{self.class.target(resource)}/command/#{resource[:name]}")
    end
  end

  def command=(value)
    self.class.augopen(resource) do |aug, path|
      aug.set("/files#{self.class.target(resource)}/command/#{resource[:name]}", value)
      augsave!(aug)
    end
  end
end
