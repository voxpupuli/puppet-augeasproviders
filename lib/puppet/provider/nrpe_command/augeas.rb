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

  resource_path do |resource, path|
    "#{path}/command/#{resource[:name]}"
  end

  def self.instances
    augopen do |aug, path|
      resources = []
      aug.match("#{path}/command/*").each do |spath|
        resource = {:ensure => :present}

        resource[:name] = spath.split("/")[-1]
        resource[:command] = aug.get("#{spath}")

        resources << new(resource)
      end
      resources
    end
  end

  def create 
    augopen(true) do |aug, path|
      aug.set("#{path}/command[last()+1]/#{resource[:name]}", resource[:command])
    end
  end

  def destroy
    augopen(true) do |aug, path|
      aug.rm("#{path}/command[#{resource[:name]}]")
    end
  end

  def command
    augopen do |aug, path|
      aug.get('$resource')
    end
  end

  def command=(value)
    augopen(true) do |aug, path|
      aug.set('$resource', value)
    end
  end
end
