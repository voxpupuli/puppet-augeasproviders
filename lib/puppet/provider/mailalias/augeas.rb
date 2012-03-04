#
# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2012 Dominic Cleal
# Licensed under the Apache License, Version 2.0
#

require 'augeas' if Puppet.features.augeas?

Puppet::Type.type(:mailalias).provide(:augeas) do
  desc "Uses Augeas API to update mail aliases file"

  confine :true   => Puppet.features.augeas? 
  confine :exists => "/etc/aliases"

  def exists? 
    aug = nil
    path = "/files#{file(resource)}"
    begin
      aug = augopen(resource)
      not aug.match("#{path}/*[name = '#{resource[:name]}']").empty?
    ensure
      aug.close if aug
    end
  end

  def create 
    aug = nil
    path = "/files#{file(resource)}"
    begin
      aug = augopen(resource)
      aug.set("#{path}/01/name", resource[:name])

      resource[:recipient].each do |rcpt|
        aug.set("#{path}/01/value[last()+1]", rcpt)
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
      aug.rm("#{path}/*[name = '#{resource[:name]}']")
      aug.save!
    ensure
      aug.close if aug
    end
  end

  def target
    file(resource)
  end

  def recipient
    aug = nil
    path = "/files#{file(resource)}"
    begin
      aug = augopen(resource)
      aliases = []
      aug.match("#{path}/*[name = '#{resource[:name]}']/value").each do |apath|
        aliases << aug.get(apath)
      end
      aliases
    ensure
      aug.close if aug
    end
  end

  def recipient=(values)
    aug = nil
    path = "/files#{file(resource)}"
    entry = "#{path}/*[name = '#{resource[:name]}']"
    begin
      aug = augopen(resource)
      aug.rm("#{entry}/value")

      values.each do |rcpt|
        aug.set("#{entry}/value[last()+1]", rcpt)
      end

      aug.save!
    ensure
      aug.close if aug
    end
  end

  private

  def file(resource)
    file = resource[:target] or "/etc/aliases"
    file.chomp("/")
  end

  def augopen(resource)
    aug = nil
    file = file(resource)
    begin
      aug = Augeas.open(nil, nil, Augeas::NO_MODL_AUTOLOAD)
      aug.transform(
        :lens => "Aliases.lns",
        :name => "Aliases",
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
