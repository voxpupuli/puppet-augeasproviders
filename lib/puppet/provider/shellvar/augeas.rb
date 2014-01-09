# Alternative Augeas-based provider for shellvar type
#
# Copyright (c) 2012 Dominic Cleal
# Licensed under the Apache License, Version 2.0

require 'augeasproviders/provider'

Puppet::Type.type(:shellvar).provide(:augeas) do
  desc "Uses Augeas API to update shell script variables"

  include AugeasProviders::Provider

  confine :feature => :augeas

  lens { 'Shellvars.lns' }

  resource_path do |resource|
    "$target/#{resource[:variable]}|$target/@unset[.='#{resource[:variable]}']"
  end

  def is_array?(path=nil, aug=nil)
    if aug.nil? || path.nil?
      augopen do |aug|
        not aug.match("$target/#{resource[:name]}/1").empty?
      end
    else
      not aug.match("$target/#{resource[:name]}/1").empty?
    end
  end

  def is_exported?
    augopen do |aug|
      not aug.match("$target/#{resource[:variable]}/export").empty?
    end
  end

  def is_unset?
    augopen do |aug|
      not aug.match("$target/@unset[.='#{resource[:variable]}']").empty?
    end
  end

  def export
    augopen! do |aug|
      unset_path = "$target/@unset[.='#{resource[:variable]}']"
      unless aug.match(unset_path).empty?
        aug.insert(unset_path, resource[:variable], false)
        set_values('$target', aug, resource[:value])
        aug.rm(unset_path)
      end
      aug.clear("$target/#{resource[:variable]}/export")
    end
  end

  def unset
    augopen! do |aug|
      aug.insert("$target/#{resource[:variable]}", '@unset', false)
      aug.set("$target/@unset[.='']", resource[:variable])
      aug.rm("$target/#{resource[:variable]}")
    end
  end

  def unexport
    augopen! do |aug|
      aug.rm("$target/#{resource[:variable]}/export")
      # Values may have changed, too
      set_values('$target', aug, resource[:value])
    end
  end

  def ununset
    augopen! do |aug|
      unset_path = "$target/@unset[.='#{resource[:variable]}']"
      aug.insert(unset_path, resource[:variable], false)
      set_values('$target', aug, resource[:value])
      aug.rm(unset_path)
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
    if is_array?(path, aug)
      aug.match('$resource/*').map { |p| aug.get(p) }
    else
      value = aug.get('$resource')
      if value =~ /^(["'])(.*)(\1)$/
        value = $2
      end
      [value]
    end
  end

  def set_values(path, aug, values)
    oldvalue = nil

    # Detect array type *before* removing subnodes
    my_array_type = array_type(path, aug)
    # Remove in any case, because we might convert an array to a string
    aug.rm("#{path}/#{resource[:variable]}/*")
    case my_array_type
    when :string
      oldvalue = aug.get("#{path}/#{resource[:variable]}")
      aug.set("#{path}/#{resource[:variable]}", quoteit(values.join(' '), oldvalue))
    when :array
      values.each_with_index do |v, i|
        aug.set("#{path}/#{resource[:variable]}/#{i}", quoteit(v))
      end
    end
  end

  def create
    augopen! do |aug|
      # Prefer to create the node next to a commented out entry
      commented = aug.match("$target/#comment[.=~regexp('#{resource[:name]}([^a-z\.].*)?')]")

      if resource[:ensure] == :unset
        unless commented.empty?
          aug.insert(commented.first, '@unset', false)
          aug.rm(commented.first) if resource[:uncomment] == :true
        end
        aug.set("$target/@unset[.='']", resource[:variable])
      else
        unless commented.empty?
          aug.insert(commented.first, resource[:name], false)
          aug.rm(commented.first) if resource[:uncomment] == :true
        end
        set_values('$target', aug, resource[:value])
        aug.clear("$target/#{resource[:variable]}/export") if resource[:ensure] == :exported
      end

      if resource[:comment]
        aug.insert("#{resource_path}", "#comment", true)
        new_node = after_comment_node(resource)
        aug.set("$target/#comment[following-sibling::*[1][self::#{new_node}]]",
                "#{resource[:variable]}: #{resource[:comment]}")
      end
    end
  end

  def after_comment_node(resource)
    if resource[:ensure] == :unset
      "@unset[.='#{resource[:variable]}']"
    else
      resource[:variable]
    end
  end

  def destroy
    augopen! do |aug|
      after_comment = after_comment_node(resource)
      aug.rm("$target/#comment[following-sibling::*[1][self::#{after_comment}]][. =~ regexp('#{resource[:variable]}:.*')]")
      aug.rm("$target/#{resource[:variable]}")
      aug.rm("$target/@unset[.='#{resource[:variable]}']")
    end
  end

  def value
    augopen do |aug|
      get_values('$target', aug)
    end
  end

  def value=(value)
    augopen! do |aug|
      set_values('$target', aug, value)
    end
  end

  def comment
    augopen do |aug|
      after_comment = after_comment_node(resource)
      comment = aug.get("$target/#comment[following-sibling::*[1][self::#{after_comment}]][. =~ regexp('#{resource[:variable]}:.*')]")
      comment.sub!(/^#{resource[:variable]}:\s*/, "") if comment
      comment || ""
    end
  end

  def comment=(value)
    augopen! do |aug|
      after_comment = after_comment_node(resource)
      cmtnode = "$target/#comment[following-sibling::*[1][self::#{after_comment}]][. =~ regexp('#{resource[:variable]}:.*')]"
      if value.empty?
        aug.rm(cmtnode)
      else
        if aug.match(cmtnode).empty?
          aug.insert("$target/#{resource[:variable]}", "#comment", true)
        end
        aug.set("$target/#comment[following-sibling::*[1][self::#{after_comment}]]",
                "#{resource[:variable]}: #{resource[:comment]}")
      end
    end
  end
end
