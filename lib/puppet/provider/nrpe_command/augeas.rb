# Alternative Augeas-based provider for nrpe type
#
# Copyright (c) 2012 Christian Kaenzig
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Puppet::Type.type(:nrpe_command).provide(:augeas) do
  desc "Uses Augeas API to update nrpe commands"

  include AugeasProviders::Provider

  default_file { '/etc/nagios/nrpe.cfg' }

  lens { 'Nrpe.lns' }

  confine :feature => :augeas

  resource_path do |resource|
    "$target/command[#{resource[:name]}]/#{resource[:name]}"
  end

  def self.instances
    augopen do |aug|
      aug.match("$target/command/*").map do |spath|
        new({
          :ensure  => :present,
          :name    => path_label(aug, spath),
          :command => aug.get(spath)
        })
      end
    end
  end

  define_aug_method!(:create) do |aug, resource|
    aug.defnode('resource', resource_path(resource), nil)
    attr_aug_writer_command(aug, resource[:command])
  end

  define_aug_method!(:destroy) do |aug, resource|
    aug.rm("$target/command[#{resource[:name]}]")
  end

  attr_aug_accessor(:command, :label => :resource)
end
