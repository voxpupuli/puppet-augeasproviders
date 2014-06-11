# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2012 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

Puppet::Type.type(:syslog).provide(:augeas, :parent => Puppet::Type.type(:augeasprovider).provider(:default)) do
  desc "Uses Augeas API to update a syslog.conf entry"

  default_file { '/etc/syslog.conf' }

  lens do |resource|
    if resource and resource[:lens]
      resource[:lens]
    else
      'Syslog.lns'
    end
  end

  confine :feature => :augeas

  resource_path do |resource|
    entry_path(resource)
  end

  def protocol_supported?
    return @protocol_supported unless @protocol_supported.nil?
    @protocol_supported = Puppet::Util::Package.versioncmp(aug_version, '1.2.0') >= 0
    @protocol_supported ||= parsed_as?("*.* @syslog.far.away:123\n", 'entry/action/protocol')
  end

  # We need to define an entry_path method
  # so the rsyslog provider can use it
  def self.entry_path(resource)
    facility = resource[:facility]
    level = resource[:level]
    action_type = resource[:action_type]
    action = resource[:action]

    # TODO: make it case-insensitive
    "$target/entry[selector/facility='#{facility}' and selector/level='#{level}' and action/#{action_type}='#{action}']"
  end

  def self.instances
    augopen do |aug|
      resources = []

      aug.match("$target/entry").each do |apath|
        aug.match("#{apath}/selector").each do |snode|
          aug.match("#{snode}/facility").each do |fnode|
            facility = aug.get(fnode) 
            level = aug.get("#{snode}/level")
            no_sync = aug.match("#{apath}/action/no_sync").empty? ? :false : :true
            action_type_node = aug.match("#{apath}/action/*[label() != 'no_sync']")
            action_type = path_label(aug, action_type_node[0])
            action_port = aug.get("#{apath}/action/port")
            action = aug.get("#{apath}/action/#{action_type}")
            name = "#{facility}.#{level} "
            name += "-" if no_sync == :true
            name += aug.get("#{apath}/action/protocol") if action_type == "hostname"
            name += "#{action}"
            entry = {:ensure => :present, :name => name,
                     :facility => facility, :level => level,
                     :no_sync => no_sync,
                     :action_type => action_type,
                     :action_port => action_port,
                     :action => action}
            resources << new(entry)
          end
        end
      end

      resources
    end
  end

  def create 
    facility = resource[:facility]
    level = resource[:level]
    no_sync = resource[:no_sync]
    action_type = resource[:action_type]
    action_port = resource[:action_port]
    action_protocol = resource[:action_protocol]
    action = resource[:action]
    augopen! do |aug|
      # TODO: make it case-insensitive
      aug.defnode('resource', resource_path, nil)
      aug.set('$resource/selector/facility', facility)
      aug.set('$resource/selector/level', level)
      if no_sync == :true and action_type == 'file'
        aug.clear('$resource/action/no_sync')
      end
      if action_protocol
        raise(Puppet::Error, 'Protocol is not supported in this lens') unless protocol_supported?
        aug.set('$resource/action/protocol', action_protocol)
      end
      aug.set("$resource/action/#{action_type}", action)
      aug.set('$resource/action/port', action_port) if action_port
    end
  end

  def no_sync
    augopen do |aug|
      if aug.match('$resource/action/no_sync').empty?
        :false
      else
        :true
      end
    end
  end

  def no_sync=(no_sync)
    augopen! do |aug|
      if no_sync == :true
        if aug.match('$resource/action/no_sync').empty?
          # Insert a no_sync node before the action/file node
          aug.insert('$resource/action/file', "no_sync", true)
        end
      else
        # Remove the no_sync tag
        aug.rm('$resource/action/no_sync')
      end
    end
  end
end
