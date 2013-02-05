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

  def directive(path)
    path.split('/')[-1]
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
    if resource[:value] == '-absent'
      print "REMOVE"
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

      #commented = aug.match("#{path}/#comment[.=~regexp('#{resource[:name]}([^a-z\.].*)?')]")
      aug.set("#{self.base_path}/directive[last()+1]", "SetEnv")
      aug.set("#{self.base_path}/directive[last()]/arg[1]", resource[:name])
      if resource[:value]
        aug.set("#{self.base_path}/directive[last()]/arg[2]", resource[:value])
      end

      #if resource[:comment]
        #aug.insert("#{path}/#{resource[:name]}", "#comment", true)
        #aug.set("#{path}/#comment[following-sibling::*[1][self::#{resource[:name]}]]",
                #"#{resource[:name]}: #{resource[:comment]}")
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
      aug.get(paths[-1] + '/arg[2]')
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
