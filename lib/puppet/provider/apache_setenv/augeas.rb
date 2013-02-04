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

  def get_name(name)
    aug = nil

    begin
      instances = []

      aug = self.class.augopen(resource)
      aug.match("#{self.base_path}/directive[.='SetEnv']").each do |path|
        name_path = path + '/arg[1]'
        value_path = path + '/arg[2]'

        name = aug.get(name_path)
        if resource[:name] == name
          instances << {
            :path => path,
            :name_path => name_path,
            :value_path => value_path,
            :name => name,
            :value => aug.get(value_path)
          }
        end
      end
      instances
    ensure
      aug.close if aug
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
    nodes = get_name(resource[:name])
    if nodes.size == 0
      false
    else
      exists = nodes[0][:name] == resource[:name]
    end
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

  def target
    self.class.file(resource)
  end

  def value
    get_name(resource[:name])[0][:value]
  end

  def value=(value)
    node = get_name(resource[:name])[0]

    aug = nil
    begin
      aug = self.class.augopen(resource)
      aug.set(node[:value_path], resource[:value])
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end
end
