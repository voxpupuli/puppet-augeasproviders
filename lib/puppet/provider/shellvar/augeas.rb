# Alternative Augeas-based provider for shellvar type
#
# Copyright (c) 2012 Dominic Cleal
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Puppet::Type.type(:shellvar).provide(:augeas) do
  desc "Uses Augeas API to update shell script variables"

  include AugeasProviders::Provider

  confine :feature => :augeas

  lens { 'Shellvars.lns' }

  def readquote(value)
    if value
      case value[0,1]
      when '"' then :double
      when "'" then :single
      else nil end
    else
      nil
    end
  end

  def quoteit(value, oldvalue = nil)
    oldquote = readquote oldvalue

    quote = resource[:quoted]
    if quote == :auto
      quote = if oldquote
        oldquote
      elsif value =~ /[|&;()<>\s]/
        :double
      else
        :none
      end
    end

    case quote
    when :double
      "\"#{value}\""
    when :single
      "'#{value}'"
    else
      value
    end
  end

  def is_array?(path=nil, aug=nil)
    if aug.nil? || path.nil?
      augopen do |aug, path|
        not aug.match("#{path}/#{resource[:name]}/1").empty?
      end
    else
      not aug.match("#{path}/#{resource[:name]}/1").empty?
    end
  end

  def array_type(path=nil, aug=nil)
    if resource[:array_type] == :auto
      if is_array?(path, aug)
        :array
      else
        :string
      end
    else
      resource[:array_type]
    end
  end

  def get_values(path, aug)
    resource_path = "#{path}/#{resource[:variable]}"
    if is_array?(path, aug)
      aug.match("#{resource_path}/*").map { |p| aug.get(p) }
    else
      value = aug.get("#{resource_path}")
      if value =~ /^(["'])(.*)(\1)$/
        value = $2
      end
      [value]
    end
  end

  def set_values(path, aug)
    oldvalue = nil

    # Detect array type *before* removing subnodes
    my_array_type = array_type(path, aug)
    # Remove in any case, because we might convert an array to a string
    aug.rm("#{path}/#{resource[:variable]}/*")
    case my_array_type
    when :string
      oldvalue = aug.get("#{path}/#{resource[:variable]}")
      aug.set("#{path}/#{resource[:variable]}", quoteit(resource[:value].join(' '), oldvalue))
    when :array
      resource[:value].each_with_index do |v, i|
        aug.set("#{path}/#{resource[:variable]}/#{i}", quoteit(v))
      end
    end
  end

  def exists?
    augopen do |aug, path|
      not aug.match("#{path}/#{resource[:variable]}").empty?
    end
  end

  def create
    augopen do |aug, path|
      # Prefer to create the node next to a commented out entry
      commented = aug.match("#{path}/#comment[.=~regexp('#{resource[:name]}([^a-z\.].*)?')]")
      aug.insert(commented.first, resource[:name], false) unless commented.empty?
      set_values(path, aug)

      if resource[:comment]
        aug.insert("#{path}/#{resource[:variable]}", "#comment", true)
        aug.set("#{path}/#comment[following-sibling::*[1][self::#{resource[:variable]}]]",
                "#{resource[:variable]}: #{resource[:comment]}")
      end
      augsave!(aug)
    end
  end

  def destroy
    augopen do |aug, path|
      aug.rm("#{path}/#comment[following-sibling::*[1][self::#{resource[:variable]}]][. =~ regexp('#{resource[:variable]}:.*')]")
      aug.rm("#{path}/#{resource[:variable]}")
      augsave!(aug)
    end
  end

  def value
    augopen do |aug, path|
      get_values(path, aug)
    end
  end

  def value=(value)
    augopen do |aug, path|
      set_values(path, aug)
      augsave!(aug)
    end
  end

  def comment
    augopen do |aug, path|
      comment = aug.get("#{path}/#comment[following-sibling::*[1][self::#{resource[:variable]}]][. =~ regexp('#{resource[:variable]}:.*')]")
      comment.sub!(/^#{resource[:variable]}:\s*/, "") if comment
      comment || ""
    end
  end

  def comment=(value)
    augopen do |aug, path|
      cmtnode = "#{path}/#comment[following-sibling::*[1][self::#{resource[:variable]}]][. =~ regexp('#{resource[:variable]}:.*')]"
      if value.empty?
        aug.rm(cmtnode)
      else
        if aug.match(cmtnode).empty?
          aug.insert("#{path}/#{resource[:variable]}", "#comment", true)
        end
        aug.set("#{path}/#comment[following-sibling::*[1][self::#{resource[:variable]}]]",
                "#{resource[:variable]}: #{resource[:comment]}")
      end
      augsave!(aug)
    end
  end
end
