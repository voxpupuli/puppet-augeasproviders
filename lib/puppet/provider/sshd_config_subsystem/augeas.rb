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

  resource_path do |resource, path|
    "$target/Subsystem/#{resource[:name]}"
  end

  def self.instances
    augopen do |aug, path|
      resources = []
      aug.match("$target/Subsystem/*").each do |hpath|
        name = path_label(aug, hpath)

        value = aug.get(hpath)
        entry = {:ensure => :present, :name => name, :command => value}
        resources << new(entry) if entry[:command]
      end
      resources
    end
  end

  def create 
    augopen! do |aug, path|
      key = resource[:name]
      unless aug.match("$target/Match").empty?
        aug.insert("$target/Match[1]", "Subsystem", true)
        aug.clear("$target/Subsystem[last()]/#{key}")
      end
      aug.set(resource_path, resource[:command])
    end
  end

  def destroy
    augopen! do |aug, path|
      key = resource[:name]
      aug.rm("$target/Subsystem[#{key}]")
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
