# Alternative Augeas-based provider for sysctl type
#
# Copyright (c) 2012 Dominic Cleal
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Puppet::Type.type(:sysctl).provide(:augeas) do
  desc "Uses Augeas API to update sysctl settings"

  include AugeasProviders::Provider

  def self.file(resource = nil)
    file = "/etc/sysctl.conf"
    file = resource[:target] if resource and resource[:target]
    file.chomp("/")
  end

  confine :feature => :augeas
  confine :exists => file

  def self.augopen(resource = nil)
    AugeasProviders::Provider.augopen("Sysctl.lns", file(resource))
  end

  def self.instances
    aug = nil
    path = "/files#{file}"
    begin
      resources = []
      aug = augopen
      aug.match("#{path}/*").each do |spath|
        resource = {:ensure => :present}

        basename = spath.split("/")[-1]
        resource[:name] = basename.split("[")[0]
        next unless resource[:name]
        next if resource[:name] == "#comment"

        resource[:value] = aug.get("#{spath}")

        # Only match comments immediately before the entry and prefixed with
        # the sysctl name
        cmtnode = aug.match("#{path}/#comment[following-sibling::*[1][self::#{basename}]]")
        unless cmtnode.empty?
          comment = aug.get(cmtnode[0])
          if comment.match(/#{resource[:name]}:/)
            resource[:comment] = comment.sub(/^#{resource[:name]}:\s*/, "")
          end
        end

        resources << new(resource)
      end
      resources
    ensure
      aug.close if aug
    end
  end

  def exists? 
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      not aug.match("#{path}/#{resource[:name]}").empty?
    ensure
      aug.close if aug
    end
  end

  def create 
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)

      # Prefer to create the node next to a commented out entry
      commented = aug.match("#{path}/#comment[.=~regexp('#{resource[:name]}([^a-z\.].*)?')]")
      aug.insert(commented.first, resource[:name], false) unless commented.empty?
      aug.set("#{path}/#{resource[:name]}", resource[:value])

      if resource[:comment]
        aug.insert("#{path}/#{resource[:name]}", "#comment", true)
        aug.set("#{path}/#comment[following-sibling::*[1][self::#{resource[:name]}]]",
                "#{resource[:name]}: #{resource[:comment]}")
      end
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def destroy
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      aug.rm("#{path}/#comment[following-sibling::*[1][self::#{resource[:name]}]][. =~ regexp('#{resource[:name]}:.*')]")
      aug.rm("#{path}/#{resource[:name]}")
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
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      aug.get("#{path}/#{resource[:name]}")
    ensure
      aug.close if aug
    end
  end

  def value=(value)
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      aug.set("#{path}/#{resource[:name]}", value)
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def comment
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      comment = aug.get("#{path}/#comment[following-sibling::*[1][self::#{resource[:name]}]][. =~ regexp('#{resource[:name]}:.*')]")
      comment.sub!(/^#{resource[:name]}:\s*/, "") if comment
      comment || ""
    ensure
      aug.close if aug
    end
  end

  def comment=(value)
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      cmtnode = "#{path}/#comment[following-sibling::*[1][self::#{resource[:name]}]][. =~ regexp('#{resource[:name]}:.*')]"
      if value.empty?
        aug.rm(cmtnode)
      else
        if aug.match(cmtnode).empty?
          aug.insert("#{path}/#{resource[:name]}", "#comment", true)
        end
        aug.set("#{path}/#comment[following-sibling::*[1][self::#{resource[:name]}]]",
                "#{resource[:name]}: #{resource[:comment]}")
      end
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end
end
