# Alternative Augeas-based provider for shellvar type
#
# Copyright (c) 2012 Dominic Cleal
# Licensed under the Apache License, Version 2.0

require 'augeasproviders/provider'

Puppet::Type.type(:shellvar).provide(:augeas) do
  desc "Uses Augeas API to update shell script variables"

  include AugeasProviders::Provider

  confine :feature => :augeas

  def self.file(resource)
    file = resource[:target]
    file.chomp("/")
  end

  def self.augopen(resource)
    AugeasProviders::Provider.augopen("Shellvars.lns", file(resource))
  end

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

  def is_array?(aug=nil)
    path = "/files#{self.class.file(resource)}"
    if aug.nil?
      aug = self.class.augopen(resource)
      aug_created = true
    end
    begin
      not aug.match("#{path}/#{resource[:name]}/1").empty?
    ensure
      aug.close if aug and aug_created
    end
  end

  def array_type(aug=nil)
    if resource[:array_type] == :auto
      if is_array?(aug)
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
    if is_array?(aug)
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
    my_array_type = array_type(aug)
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
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      not aug.match("#{path}/#{resource[:variable]}").empty?
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
      set_values(path, aug)

      if resource[:comment]
        aug.insert("#{path}/#{resource[:variable]}", "#comment", true)
        aug.set("#{path}/#comment[following-sibling::*[1][self::#{resource[:variable]}]]",
                "#{resource[:variable]}: #{resource[:comment]}")
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
      aug.rm("#{path}/#comment[following-sibling::*[1][self::#{resource[:variable]}]][. =~ regexp('#{resource[:variable]}:.*')]")
      aug.rm("#{path}/#{resource[:variable]}")
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
      get_values(path, aug)
    ensure
      aug.close if aug
    end
  end

  def value=(value)
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      set_values(path, aug)
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
      comment = aug.get("#{path}/#comment[following-sibling::*[1][self::#{resource[:variable]}]][. =~ regexp('#{resource[:variable]}:.*')]")
      comment.sub!(/^#{resource[:variable]}:\s*/, "") if comment
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
    ensure
      aug.close if aug
    end
  end
end
