# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2012 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

require 'augeas' if Puppet.features.augeas?

Puppet::Type.type(:sshd_config).provide(:augeas) do
  desc "Uses Augeas API to update an sshd_config parameter"

  def self.file(resource = nil)
    file = "/etc/ssh/sshd_config"
    file = resource[:target] if resource and resource[:target]
    file.chomp("/")
  end

  confine :true   => Puppet.features.augeas? 
  confine :exists => file

  def self.augopen(resource = nil)
    aug = nil
    file = file(resource)
    begin
      aug = Augeas.open(nil, nil, Augeas::NO_MODL_AUTOLOAD)
      aug.transform(
        :lens => "Sshd.lns",
        :name => "Sshd",
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

  def self.instances
    aug = nil
    path = "/files#{file}"
    entry_path = self.class.entry_path(resource)
    begin
      resources = []
      aug = augopen
      aug.match(entry_path).each do |hpath|
        entry = {}
        entry[:name] = resource[:name]
        entry[:conditions] = Hash[*resource[:condition].split(' ').flatten(1)]
        entry[:value] = aug.get(hpath)

        resources << new(entry)
      end
      resources
    ensure
      aug.close if aug
    end
  end

  def self.match_conditions(resource=nil)
    if resource[:condition]
      conditions = Hash[*resource[:condition].split(' ').flatten(1)]
      cond_keys = conditions.keys.length
      cond_str = "[count(Condition/*)=#{cond_keys}]"
      conditions.each { |k,v| cond_str += "[Condition/#{k}=\"#{v}\"]" }
      cond_str
    else
      ""
    end
  end

  def self.entry_path(resource=nil)
    path = "/files#{self.file(resource)}"
    if resource[:condition]
      cond_str = self.match_conditions(resource)
      "#{path}/Match#{cond_str}/Settings/#{resource[:name]}"
    else
      "#{path}/#{resource[:name]}"
    end
  end

  def self.match_exists?(resource=nil)
    aug = nil
    path = "/files#{self.file(resource)}"
    begin
      aug = self.augopen(resource)
      if resource[:condition]
        cond_str = self.match_conditions(resource)
      else
        false
      end
      not aug.match("#{path}/Match#{cond_str}").empty?
    ensure
      aug.close if aug
    end
  end

  def exists? 
    aug = nil
    entry_path = self.class.entry_path(resource)
    begin
      aug = self.class.augopen(resource)
      not aug.match(entry_path).empty?
    ensure
      aug.close if aug
    end
  end

  def self.create_match(resource=nil, aug=nil)
    path = "/files#{self.file(resource)}"
    begin
      aug.insert("#{path}/*[last()]", "Match", false)
      conditions = Hash[*resource[:condition].split(' ').flatten(1)]
      conditions.each do |k,v|
        aug.set("#{path}/Match[last()]/Condition/#{k}", v)
      end
      aug
    end
  end

  def create 
    aug = nil
    path = "/files#{self.class.file(resource)}"
    entry_path = self.class.entry_path(resource)
    begin
      aug = self.class.augopen(resource)
      if resource[:condition]
        unless self.class.match_exists?(resource)
          aug = self.class.create_match(resource, aug)
        end
      else
        unless aug.match("#{path}/Match").empty?
          aug.insert("#{path}/Match[1]", resource[:name], true)
        end
      end
      aug.set(entry_path, resource[:value])
      aug.save!
    ensure
      aug.close if aug
    end
  end

  def destroy
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      aug.rm(entry_path)
      aug.rm("#{path}/Match[count(Settings/*)=0]")
      aug.save!
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
      entry_path = self.class.entry_path(resource)
      aug.get(entry_path)
    ensure
      aug.close if aug
    end
  end

  def value=(thevalue)
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      aug.set(entry_path, thevalue)
      aug.save!
    ensure
      aug.close if aug
    end
  end
end
