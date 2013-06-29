# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2012 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Puppet::Type.type(:sshd_config_subsystem).provide(:augeas) do
  desc "Uses Augeas API to update a Subsystem parameter in sshd_config."

  include AugeasProviders::Provider

  default_file { '/etc/ssh/sshd_config' }

  lens { 'Sshd.lns' }

  confine :feature => :augeas
  confine :exists => target

  resource_path do |resource|
    "/files#{target(resource)}/Subsystem/#{resource[:name]}"
  end

  def self.path_label(path)
    path.split("/")[-1]
  end

  def self.instances
    augopen do |aug, path|
      resources = []
      aug.match("#{path}/Subsystem/*").each do |hpath|
        name = self.path_label(hpath)

        value = aug.get(hpath)
        entry = {:ensure => :present, :name => name, :command => value}
        resources << new(entry) if entry[:command]
      end
      resources
    end
  end

  def exists? 
    augopen do |aug, path|
      not aug.match(resource_path).empty?
    end
  end

  def create 
    augopen do |aug, path|
      key = resource[:name]
      unless aug.match("#{path}/Match").empty?
        aug.insert("#{path}/Match[1]", "Subsystem", true)
        aug.clear("#{path}/Subsystem[last()]/#{key}")
      end
      aug.set(resource_path, resource[:command])
      augsave!(aug)
    end
  end

  def destroy
    augopen do |aug, path|
      key = resource[:name]
      aug.rm("#{path}/Subsystem[#{key}]")
      augsave!(aug)
    end
  end

  def command
    augopen do |aug, path|
      aug.get(resource_path)
    end
  end

  def command=(value)
    augopen do |aug, path|
      aug.set(resource_path, value)
      augsave!(aug)
    end
  end
end
