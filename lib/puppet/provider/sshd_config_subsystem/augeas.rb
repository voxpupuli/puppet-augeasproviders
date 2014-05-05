# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2012 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

Puppet::Type.type(:sshd_config_subsystem).provide(:augeas, :parent => Puppet::Type.type(:augeasprovider).provider(:default)) do
  desc "Uses Augeas API to update a Subsystem parameter in sshd_config."

  default_file { '/etc/ssh/sshd_config' }

  lens { 'Sshd.lns' }

  confine :feature => :augeas

  resource_path do |resource|
    if supported?(:regexpi)
      "$target/*[label()=~regexp('Subsystem', 'i')]/#{resource[:name]}"
    else
      "$target/Subsystem/#{resource[:name]}"
    end
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
    aug.set("$target/Subsystem/#{resource[:name]}", resource[:command])
  end

  define_aug_method!(:destroy) do |aug, resource|
    key = resource[:name]
    if supported?(:regexpi)
      aug.rm("$target/*[label()=~regexp('Subsystem', 'i') and #{key}]")
    else
      aug.rm("$target/Subsystem[#{key}]")
    end
  end

  attr_aug_accessor(:command, :label => :resource)
end
