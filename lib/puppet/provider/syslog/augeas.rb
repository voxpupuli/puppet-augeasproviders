# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2012 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Puppet::Type.type(:syslog).provide(:augeas) do
  desc "Uses Augeas API to update a syslog.conf entry"

  include AugeasProviders::Provider

  def self.file(resource = nil)
    file = "/etc/syslog.conf"
    file = resource[:target] if resource and resource[:target]
    file.chomp("/")
  end

  confine :feature => :augeas

  def self.augopen(resource = nil)
    lens = "Syslog.lns"
    lens = resource[:lens] if resource and resource[:lens]
    AugeasProviders::Provider.augopen(lens, file(resource))
  end

  def self.entry_path(resource)
    path = "/files#{self.file(resource)}"
    facility = resource[:facility]
    level = resource[:level]
    action_type = resource[:action_type]
    action = resource[:action]

    # TODO: make it case-insensitive
    "#{path}/entry[selector/facility='#{facility}' and selector/level='#{level}' and action/#{action_type}='#{action}']"
  end

  def self.path_label(path)
    path.split("/")[-1].split("[")[0]
  end

  def self.get_value(aug, pathx)
    aug.get(pathx)
  end

  def self.instances
    aug = nil
    begin
      resources = []
      aug = augopen

      aug.match("/files#{file}/entry").each do |path|
        aug.match("#{path}/selector").each do |snode|
          aug.match("#{snode}/facility").each do |fnode|
            facility = self.get_value(aug, fnode) 
            level = self.get_value(aug, "#{snode}/level")
            no_sync = aug.match("#{path}/action/no_sync").empty? ? :false : :true
            action_type_node = aug.match("#{path}/action/*[label() != 'no_sync']")
            action_type = self.path_label(action_type_node[0])
            action = self.get_value(aug, "#{path}/action/#{action_type}")
            name = "#{facility}.#{level} "
            name += "-" if no_sync == :true
            name += "@" if action_type == "hostname"
            name += "#{action}"
            entry = {:ensure => :present, :name => name,
                     :facility => facility, :level => level,
                     :no_sync => no_sync,
                     :action_type => action_type, :action => action}
            resources << new(entry)
          end
        end
      end

      resources
    ensure
      aug.close if aug
    end
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
    facility = resource[:facility]
    level = resource[:level]
    no_sync = resource[:no_sync]
    action_type = resource[:action_type]
    action = resource[:action]
    begin
      aug = self.class.augopen(resource)
      # TODO: make it case-insensitive
      aug.set("#{entry_path}/selector/facility", facility)
      aug.set("#{path}/*[last()]/selector/level", level)
      if no_sync == :true and action_type == 'file'
        aug.clear("#{path}/*[last()]/action/no_sync")
      end
      aug.set("#{path}/*[last()]/action/#{action_type}", action)
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
      entry_path = self.class.entry_path(resource)
      aug.rm(entry_path)
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def target
    self.class.file(resource)
  end

  def no_sync
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      if aug.match("#{entry_path}/action/no_sync").empty?
        :false
      else
        :true
      end
    ensure
      aug.close if aug
    end
  end

  def no_sync=(no_sync)
    aug = nil
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      if no_sync == :true
        if aug.match("#{entry_path}/action/no_sync").empty?
          # Insert a no_sync node before the action/file node
          aug.insert("#{entry_path}/action/file", "no_sync", true)
        end
      else
        # Remove the no_sync tag
        aug.rm("#{entry_path}/action/no_sync")
      end
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end
end
