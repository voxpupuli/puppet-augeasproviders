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
    "$target/Subsystem/#{resource[:name]}"
  end

  def self.instances
    augopen do |aug|
      aug.match("$target/Subsystem/*").map do |hpath|
        command = aug.get(hpath)
        new({
          :ensure  => :present,
          :name    => path_label(aug, hpath),
          :command => command
        }) if command
      end
    end
  end

  define_aug_method!(:create) do |aug, resource|
    key = resource[:name]
    unless aug.match("$target/Match").empty?
      aug.insert("$target/Match[1]", "Subsystem", true)
      aug.clear("$target/Subsystem[last()]/#{key}")
    end
    aug.set(resource_path(resource), resource[:command])
  end

  define_aug_method!(:destroy) do |aug, resource|
    key = resource[:name]
    aug.rm("$target/Subsystem[#{key}]")
  end

  attr_aug_accessor(:command, :label => :resource)
end
