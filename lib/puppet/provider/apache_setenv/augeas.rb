# Manages SetEnv entries in a Apache config
#
# Copyright (c) 2013 Endre Karlson
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Puppet::Type.type(:apache_setenv).provide(:augeas) do
  desc "Use Augeas API to update SetEnv in Apache"

  include AugeasProviders::Provider

  lens { 'Httpd.lns' }

  default_file do
    FileTest.exist?("/etc/httpd/conf/httpd.conf") ? "/etc/httpd/conf/httpd.conf" : "/etc/apache2/apache2.conf"
  end

  confine :feature => :augeas
  confine :exists => target

  def path_index(path)
    path[/\d+(?=\])/].to_i
  end

  def paths_from_name(aug, path)
    aug.match("#{path}/directive[.='SetEnv' and arg[1]='#{resource[:name]}']")
  end

  def self.instances
    augopen do |aug, path|
      resources = []
      aug.match("#{path}/directive[.='SetEnv']").each do |spath|
        name = aug.get("#{spath}/arg[1]")
        unless resources.detect { |r| r.name == name }
          value = aug.get("#{aug.match("#{path}/directive[.='SetEnv' and arg[1]='#{name}']").last}/arg[2]")
          resource = {:ensure => :present, :name => name, :value => value}
          resources << new(resource)
        end
      end
      resources
    end
  end

  def exists?
    paths = []
    augopen do |aug, path|
      paths = paths_from_name(aug, path)
    end
    !paths.empty?
  end

  def create
    augopen do |aug, path|
      base = "#{path}/directive"

      last_path = aug.match("#{base}[.='SetEnv']")[-1]
      if last_path
        # Prefer to insert the new node after the last SetEnv
        aug.insert(last_path, "directive", false)
        index = path_index(last_path) + 1
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
    end
  end

  def destroy
    augopen do |aug, path|
      aug.rm("#{path}/directive[.='SetEnv' and arg[1]='#{resource[:name]}']")
      augsave!(aug)
    end
  end

  def value
    augopen do |aug, path|
      paths = paths_from_name(aug, path)
      aug.get(paths.last + '/arg[2]') || ''
    end
  end

  def value=(value)
    augopen do |aug, path|
      # Get all paths, then pop the last path and remove the rest
      paths = paths_from_name(aug, path)
      path = paths.pop

      val_path = "#{path}/arg[2]"
      if resource[:value].nil? || resource[:value].empty?
        aug.rm(val_path)
      else
        aug.set(val_path, resource[:value])
      end
      paths.each { |p| aug.rm(p) }

      augsave!(aug)
    end
  end
end
