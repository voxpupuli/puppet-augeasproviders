# Alternative Augeas-based provider for sysctl type
#
# Copyright (c) 2012 Dominic Cleal
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Puppet::Type.type(:sysctl).provide(:augeas) do
  desc "Uses Augeas API to update sysctl settings"

  include AugeasProviders::Provider

  default_file { '/etc/sysctl.conf' }

  lens { 'Sysctl.lns' }

  optional_commands :sysctl => 'sysctl'

  resource_path do |resource, path|
    "$target/#{resource[:name]}"
  end

  def self.sysctl_set(key, value)
    if Facter.value(:kernel) == :openbsd
      sysctl("#{key}=#{value}")
    else
      sysctl('-w', %Q{#{key}="#{value}"})
    end
  end

  def self.sysctl_get(key)
    sysctl('-n', key).chomp
  end

  confine :feature => :augeas
  confine :exists => target

  def self.instances
    augopen do |aug, path|
      resources = []
      aug.match("$target/*").each do |spath|
        resource = {:ensure => :present}

        basename = spath.split("/")[-1]
        resource[:name] = basename.split("[")[0]
        next unless resource[:name]
        next if resource[:name] == "#comment"

        resource[:value] = aug.get("#{spath}")

        # Only match comments immediately before the entry and prefixed with
        # the sysctl name
        cmtnode = aug.match("$target/#comment[following-sibling::*[1][self::#{basename}]]")
        unless cmtnode.empty?
          comment = aug.get(cmtnode[0])
          if comment.match(/#{resource[:name]}:/)
            resource[:comment] = comment.sub(/^#{resource[:name]}:\s*/, "")
          end
        end

        resources << new(resource)
      end
      resources
    end
  end

  def create 
    # the value to pass to augeas can come either from the 'value' or the
    # 'val' type parameter.
    value = resource[:value] || resource[:val]

    augopen do |aug, path|
      # Prefer to create the node next to a commented out entry
      commented = aug.match("$target/#comment[.=~regexp('#{resource[:name]}([^a-z\.].*)?')]")
      aug.insert(commented.first, resource[:name], false) unless commented.empty?
      aug.set(resource_path, value)
      setvars(aug)

      if resource[:comment]
        aug.insert('$resource', "#comment", true)
        aug.set("$target/#comment[following-sibling::*[1][self::#{resource[:name]}]]",
                "#{resource[:name]}: #{resource[:comment]}")
      end
      augsave!(aug)
      if resource[:apply]
        self.class.sysctl_set(resource[:name], value)
      end
    end
  end

  def destroy
    augopen do |aug, path|
      aug.rm("$target/#comment[following-sibling::*[1][self::#{resource[:name]}]][. =~ regexp('#{resource[:name]}:.*')]")
      aug.rm('$resource')
      augsave!(aug)
    end
  end

  def live_value
    self.class.sysctl_get(resource[:name])
  end

  def value
    augopen do |aug, path|
      aug.get('$resource')
    end
  end

  def value=(value)
    augopen do |aug, path|
      aug.set('$resource', value)
      augsave!(aug)
      if resource[:apply] == :true
        self.class.sysctl_set(resource[:name], value)
      end
    end
  end

  alias_method :val, :value
  alias_method :val=, :value=

  def comment
    augopen do |aug, path|
      comment = aug.get("$target/#comment[following-sibling::*[1][self::#{resource[:name]}]][. =~ regexp('#{resource[:name]}:.*')]")
      comment.sub!(/^#{resource[:name]}:\s*/, "") if comment
      comment || ""
    end
  end

  def comment=(value)
    augopen do |aug, path|
      cmtnode = "$target/#comment[following-sibling::*[1][self::#{resource[:name]}]][. =~ regexp('#{resource[:name]}:.*')]"
      if value.empty?
        aug.rm(cmtnode)
      else
        if aug.match(cmtnode).empty?
          aug.insert('$resource', "#comment", true)
        end
        aug.set("$target/#comment[following-sibling::*[1][self::#{resource[:name]}]]",
                "#{resource[:name]}: #{resource[:comment]}")
      end
      augsave!(aug)
    end
  end
end
