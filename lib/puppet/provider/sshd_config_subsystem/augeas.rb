# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2012 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Puppet::Type.type(:sshd_config_subsystem).provide(:augeas) do
  desc "Uses Augeas API to update a Subsystem parameter in sshd_config."

  include AugeasProviders::Provider

  def self.file(resource = nil)
    file = "/etc/ssh/sshd_config"
    file = resource[:target] if resource and resource[:target]
    file.chomp("/")
  end

  confine :feature => :augeas
  confine :exists => file

  def self.augopen(resource = nil)
    AugeasProviders::Provider.augopen("Sshd.lns", file(resource))
  end

  def self.path_label(path)
    path.split("/")[-1]
  end

  def self.instances
    aug = nil
    begin
      resources = []
      aug = augopen
      aug.match("/files#{file}/Subsystem/*").each do |hpath|
        name = self.path_label(hpath)

        value = aug.get(hpath)
        entry = {:ensure => :present, :name => name, :command => value}
        resources << new(entry) if entry[:command]
      end
      resources
    ensure
      aug.close if aug
    end
  end

  def self.entry_path(resource)
    path = "/files#{self.file(resource)}"
    name = resource[:name]
    key = "Subsystem/#{name}"
    "#{path}/#{key}"
  end

  def exists? 
    aug = nil
    entry_path = self.class.entry_path(resource)
    begin
      aug = self.class.augopen(resource)
      not aug.match(entry_path).empty?
    ensure
      aug.close if aug
    end
  end

  def create 
    aug = nil
    path = "/files#{self.class.file(resource)}"
    entry_path = self.class.entry_path(resource)
    key = resource[:name]
    begin
      aug = self.class.augopen(resource)
      unless aug.match("#{path}/Match").empty?
        aug.insert("#{path}/Match[1]", "Subsystem", true)
        aug.clear("#{path}/Subsystem[last()]/#{key}")
      end
      aug.set(entry_path, resource[:command])
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def destroy
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      key = resource[:name]
      aug.rm("#{path}/Subsystem[#{key}]")
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def target
    self.class.file(resource)
  end

  def command
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      aug.get(entry_path)
    ensure
      aug.close if aug
    end
  end

  def command=(value)
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      aug.set(entry_path, value)
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end
end
