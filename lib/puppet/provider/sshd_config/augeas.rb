# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2012 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Puppet::Type.type(:sshd_config).provide(:augeas) do
  desc "Uses Augeas API to update an sshd_config parameter"

  include AugeasProviders::Provider

  default_file { '/etc/ssh/sshd_config' }

  lens { 'Sshd.lns' }

  confine :feature => :augeas
  confine :exists => target

  resource_path do |resource|
    base = self.base_path(resource)
    key = resource[:key] ? resource[:key] : resource[:name]
    "#{base}/#{key}"
  end

  def self.base_path(resource)
    if resource[:condition]
      "$target/Match#{self.match_conditions(resource)}/Settings"
    else
      '$target'
    end
  end

  def self.get_value(aug, pathx)
    aug.match(pathx).map do |vp|
      # Augeas lens does transparent multi-node (no counte reset) so check for any int
      if aug.match("#{vp}/*[label()=~regexp('[0-9]*')]").empty?
        aug.get(vp)
      else
        aug.match("#{vp}/*").map do |svp|
          aug.get(svp)
        end
      end
    end.flatten
  end

  def self.set_value(aug, base, path, value)
    label = path_label(aug, path)
    if path =~ /.*\/(((Allow|Deny)(Groups|Users))|AcceptEnv|MACs)(\[\d\*\])?/

      if aug.match("#{base}/Match").empty?
        # insert as the last line
        aug.insert("#{base}/*", label, false)
      else
        # before the match block so it's in the main section
        aug.insert("#{base}/Match[1]", label, true)
      end

      # Make sure only our values are used
      aug.rm("#{path}/*")
      # In case there is more than one entry, keep only the first one
      aug.rm("#{path}[position() != 1]")
      count = 0
      value.each do |v|
        count += 1
        aug.set("#{path}/#{count}", v)
      end
    else
      # Normal setting: one value per entry
      value = value.clone

      # Change any existing settings with this name
      lastsp = nil
      aug.match(path).each do |sp|
        val = value.shift
        if val.nil?
          aug.rm(sp)
        else
          aug.set(sp, val)
          lastsp = sp
        end
      end

      # Insert new values for the rest
      value.each do |v|
        if lastsp
          # After the most recent same setting (lastsp)
          aug.insert(lastsp, label, false)
          aug.set("#{path}[last()]", v)
        else
          # Prefer to create the node next to a commented out entry
          commented = aug.match("#{base}/#comment[.=~regexp('#{label}([^a-z\.].*)?')]")
          if commented.empty?
            if aug.match("#{base}/Match").empty?
              # insert as the last line
              aug.insert("#{base}/*", label, false)
            else
              # before the match block so it's in the main section
              aug.insert("#{base}/Match[1]", label, true)
            end
          else
            aug.insert(commented.first, label, false)
          end
          aug.set("#{path}[last()]", v)
        end
        lastsp = aug.match("#{path}[last()]")[0]
      end
    end
  end

  def self.instances
    augopen do |aug,path|
      resources = []
      # Ordinary settings outside of match blocks
      # Find all unique setting names, then find all instances of it
      settings = aug.match("$target/*[label()!='Match']").map {|spath|
        path_label(aug, spath)
      }.uniq.reject {|name| name.start_with?("#", "@")}

      settings.each do |name|
        value = self.get_value(aug, "$target/#{name}")
        entry = {:ensure => :present, :name => name, :value => value}
        resources << new(entry) if entry[:value]
      end

      # Settings inside match blocks
      aug.match("$target/Match").each do |mpath|
        conditions = []
        aug.match("#{mpath}/Condition/*").each do |cond_path|
          cond_name = path_label(aug, cond_path)
          cond_value = aug.get(cond_path)
          conditions.push("#{cond_name} #{cond_value}")
        end
        cond_str = conditions.join(" ")

        settings = aug.match("#{mpath}/Settings/*").map {|spath|
          path_label(aug, spath)
        }.uniq.reject {|name| name.start_with?("#", "@")}

        settings.each do |name|
          value = self.get_value(aug, "#{mpath}/Settings/#{name}")
          entry = {:ensure => :present, :name => name,
                   :value => value, :condition => cond_str}
          resources << new(entry) if entry[:value]
        end
      end
      resources
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

  def self.match_exists?(resource)
    augopen(resource) do |aug|
      cond_str = resource[:condition] ? self.match_conditions(resource) : ''
      not aug.match("$target/Match#{cond_str}").empty?
    end
  end

  def exists? 
    augopen do |aug|
      not aug.match(resource_path).empty?
    end
  end

  def create 
    augopen! do |aug|
      key = resource[:key] ? resource[:key] : resource[:name]
      if resource[:condition] && !self.class.match_exists?(resource)
        aug.insert("$target/*[last()]", "Match", false)
        conditions = Hash[*resource[:condition].split(' ').flatten(1)]
        conditions.each do |k,v|
          aug.set("$target/Match[last()]/Condition/#{k}", v)
        end
      end
      self.class.set_value(aug, self.class.base_path(resource), resource_path, resource[:value])
    end
  end

  def destroy
    augopen! do |aug|
      aug.rm('$resource')
      aug.rm('$target/Match[count(Settings/*)=0]')
    end
  end

  def value
    augopen do |aug|
      self.class.get_value(aug, '$resource')
    end
  end

  def value=(value)
    augopen! do |aug|
      self.class.set_value(aug, self.class.base_path(resource), resource_path, value)
    end
  end
end
