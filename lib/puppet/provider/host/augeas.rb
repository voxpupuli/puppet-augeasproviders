#
# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2012 Dominic Cleal
# Licensed under the Apache License, Version 2.0
#

require 'augeas' if Puppet.features.augeas?

hosts = nil
case Facter.value(:operatingsystem)
when "Solaris"
  hosts = "/etc/inet/hosts"
else
  hosts = "/etc/hosts"
end

Puppet::Type.type(:host).provide(:augeas) do
  desc "Uses Augeas API to update hosts file"

  confine :true   => Puppet.features.augeas? 
  confine :exists => hosts

  def exists? 
    aug = nil
    path = "/files#{file(resource)}"
    begin
      aug = augopen(resource)
      not aug.match("#{path}/*[canonical = '#{resource[:name]}']").empty?
    ensure
      aug.close if aug
    end
  end

  def create 
    aug = nil
    path = "/files#{file(resource)}"
    begin
      aug = augopen(resource)
      aug.set("#{path}/01/ipaddr", resource[:ip])
      aug.set("#{path}/01/canonical", resource[:name])

      if resource[:host_aliases]
        resource[:host_aliases].each do |halias|
          aug.set("#{path}/01/alias[last()+1]", halias)
        end
      end

      if resource[:comment]
        aug.set("#{path}/01/#comment", resource[:comment])
      end

      aug.save!
    ensure
      aug.close if aug
    end
  end

  def destroy
    aug = nil
    path = "/files#{file(resource)}"
    begin
      aug = augopen(resource)
      aug.rm("#{path}/*[canonical = '#{resource[:name]}']")
      aug.save!
    ensure
      aug.close if aug
    end
  end

  def target
    file(resource)
  end

  def ip
    aug = nil
    path = "/files#{file(resource)}"
    begin
      aug = augopen(resource)
      aug.get("#{path}/*[canonical = '#{resource[:name]}']/ipaddr")
    ensure
      aug.close if aug
    end
  end

  def ip=(value)
    aug = nil
    path = "/files#{file(resource)}"
    begin
      aug = augopen(resource)
      aug.set("#{path}/*[canonical = '#{resource[:name]}']/ipaddr", value)
      aug.save!
    ensure
      aug.close if aug
    end
  end

  def host_aliases
    aug = nil
    path = "/files#{file(resource)}"
    begin
      aug = augopen(resource)
      aliases = []
      aug.match("#{path}/*[canonical = '#{resource[:name]}']/alias").each do |apath|
        aliases << aug.get(apath)
      end
      aliases.join(" ")
    ensure
      aug.close if aug
    end
  end

  def host_aliases=(values)
    aug = nil
    path = "/files#{file(resource)}"
    entry = "#{path}/*[canonical = '#{resource[:name]}']"
    begin
      aug = augopen(resource)
      aug.rm("#{entry}/alias")

      insafter = "canonical"
      values.split.each do |halias|
        aug.insert("#{entry}/#{insafter}", "alias", false)
        aug.set("#{entry}/alias[last()]", halias)
        insafter = "alias[last()]"
      end

      aug.save!
    ensure
      aug.close if aug
    end
  end

  def comment
    aug = nil
    path = "/files#{file(resource)}"
    begin
      aug = augopen(resource)
      aug.get("#{path}/*[canonical = '#{resource[:name]}']/#comment")
    ensure
      aug.close if aug
    end
  end

  def comment=(value)
    aug = nil
    path = "/files#{file(resource)}"
    begin
      aug = augopen(resource)
      aug.set("#{path}/*[canonical = '#{resource[:name]}']/#comment", value)
      aug.save!
    ensure
      aug.close if aug
    end
  end

  private

  def file(resource)
    file = resource[:target] or hosts
    file.chomp("/")
  end

  def augopen(resource)
    aug = nil
    file = file(resource)
    begin
      aug = Augeas.open(nil, nil, Augeas::NO_MODL_AUTOLOAD)
      aug.transform(
        :lens => "Hosts.lns",
        :name => "Hosts",
        :incl => file
      )
      aug.load!

      if aug.match("/files#{file}").empty?
        message = aug.get("/augeas/files#{file}/error/message")
        fail("Augeas didn't load #{file}: #{message}")
      end
    rescue
      aug.close if aug
      raise
    end
    aug
  end
end
