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

  resource_path do |resource, path|
    "command/#{resource[:name]}"
  end

  def self.instances
    augopen do |aug, path|
      aug.match("command/*").map do |spath|
        new({
          :ensure  => :present,
          :name    => path_label(aug, spath),
          :command => aug.get(spath)
        })
      end
    end
  end

  def create 
    augopen! do |aug, path|
      aug.set("command[last()+1]/#{resource[:name]}", resource[:command])
    end
  end

  def destroy
    augopen! do |aug, path|
      aug.rm("command[#{resource[:name]}]")
    end
  end

  def command
    augopen do |aug, path|
      aug.get('$resource')
    end
  end

  def command=(value)
    augopen! do |aug, path|
      aug.set('$resource', value)
    end
  end
end
