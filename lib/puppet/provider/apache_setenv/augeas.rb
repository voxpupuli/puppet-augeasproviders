# Manages SetEnv entries in a Apache config
#
# Copyright (c) 2013 Endre Karlson
# Licensed under the Apache License, Version 2.0

require 'puppet'
require 'pp'
require File.dirname(__FILE__) + '/../../../augeasproviders/provider'


Puppet::Type.type(:apache_setenv).provide(:augeas) do
  desc "Use Augeas API to update SetEnv in Apache"

  include AugeasProviders::Provider

  def self.file(resource = nil)
    file = "/etc/apache2/apache2.conf"
    file = resource[:target] if resource and resource[:target]
    file.chomp("/")
  end

  confine :feature => :augeas
  confine :exists => file

  def self.augopen(resource = nil)
    AugeasProviders::Provider.augopen("Httpd.lns", file(resource))
  end

  def base_path
    "/files#{self.class.file(resource)}"
  end

  def path_index(path)
    path[/\d+(?=\])/].to_i
  end

  def paths_from_name(aug)
    paths = []
    aug.match("#{self.base_path}/directive[.='SetEnv']").each do |path|
      next if aug.get(path + '/arg[1]') != resource[:name]
      paths << path
    end
    paths
  end

  def paths_rm(aug, paths)
    paths.each do |path|
      aug.match(path + '/*').each do |p|
        aug.rm(p)
      end
    end
  end

  def path_set_value(aug, path)
    val_path = path + '/arg[2]'
    if resource[:value] == '' || resource[:value] == nil
      aug.rm(val_path)
    else
      aug.set(val_path, resource[:value])
    end
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
    paths = []
    begin
      aug = self.class.augopen(resource)
      paths = paths_from_name(aug)
    ensure
      aug.close if aug
    end

    exists = true ? (paths.size != 0) : false
    exists
  end

  def create
    aug = nil
    begin
      aug = self.class.augopen(resource)

      base = "#{self.base_path}/directive"

      last_path = aug.match("#{base}[.=~regexp('SetEnv')]")[-1]
      if last_path
        # Prefer to insert the new node after the last SetEnv
        index = path_index(last_path) + 1
        aug.insert(self.base_path, "directive[#{index}]", false)
      else
        # If not try to determine the last path or no path...
        last_path = aug.match("#{base}[last()]")[0]
        index = last_path ? path_index(last_path) + 1 : 1
      end

      aug.set("#{base}[#{index}]", "SetEnv")
      aug.set("#{base}[#{index}]/arg[1]", resource[:name])
      if resource[:value]
        aug.set("#{base}[#{index}]/arg[2]", resource[:value])
      end

      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def destroy
    aug = nil
    begin
      aug = self.class.augopen(resource)

      paths = paths_from_name(aug)
      paths_rm(aug, paths)

      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def target
    self.class.file(resource)
  end

  def value
    aug = nil
    begin
      aug = self.class.augopen(resource)

      paths = paths_from_name(aug)
      value = aug.get(paths[-1] + '/arg[2]')
      value ? value : ''
    ensure
      aug.close if aug
    end
  end

  def value=(value)
    aug = nil
    begin
      aug = self.class.augopen(resource)

      # Get all paths, then pop the last path and remove the rest
      paths = paths_from_name(aug)
      last_path = paths.pop

      paths_rm(aug, paths)
      path_set_value(aug, last_path)

      augsave!(aug)
    ensure
      aug.close if aug
    end
  end
end
