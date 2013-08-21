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

  resource_path do |resource|
    "$target/directive[.='SetEnv' and arg[1]='#{resource[:name]}']"
  end

  confine :feature => :augeas
  confine :exists => target

  def self.instances
    augopen do |aug|
      resources = []
      aug.match('$target/directive[.="SetEnv"]').each do |spath|
        name = aug.get("#{spath}/arg[1]")
        unless resources.detect { |r| r.name == name }
          resource = {:ensure => :present, :name => name}
          resource[:value] = aug.get("#{resource_path(resource)}[last()]/arg[2]")
          resources << new(resource)
        end
      end
      resources
    end
  end

  define_aug_method!(:create) do |aug, resource|
    last_path = '$target/directive[.="SetEnv"][last()]'
    if aug.match('$target/directive[.="SetEnv"]').empty?
      aug.clear('$target/directive[last()+1]') 
    else
      # Prefer to insert the new node after the last SetEnv
      aug.insert(last_path, 'directive', false)
    end

    # The new node is the only directive without a value
    aug.defvar('new', '$target/directive[.=""]')
    aug.set('$new', 'SetEnv')
    aug.set('$new/arg[1]', resource[:name])
    if resource[:value]
      aug.set('$new/arg[2]', resource[:value])
    end
  end

  define_aug_method(:value) do |aug, resource|
    aug.get('$resource[last()]/arg[2]') || ''
  end

  define_aug_method!(:value=) do |aug, resource, value|
    # Get last path, then remove the rest
    val_path = '$resource[last()]/arg[2]'
    if resource[:value].nil? || resource[:value].empty?
      aug.rm(val_path)
    else
      aug.set(val_path, resource[:value])
    end
    aug.rm('$resource[position()!=last()]')
  end
end
