# Manages an Apache directive
#
# Copyright (c) 2013 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Puppet::Type.type(:apache_directive).provide(:augeas) do
  desc 'Use the Augeas API to update a directive in Apache'

  include AugeasProviders::Provider

  lens { 'Httpd.lns' }
  
  default_file do
    case Facter.value(:osfamily)
    when 'RedHat'
      '/etc/httpd/conf/httpd.conf'
    when 'Debian'
      '/etc/apache2/apache2.conf'
    end
  end

  resource_path do |resource|
    path = '$target'
    path += "/#{resource[:context]}" unless resource[:context].empty?
    if supported?(:regexpi)
      path += "/directive[.=~regexp('#{resource[:name]}', 'i')"
    else
      debug "Warning: Augeas >= 1.0.0 is required for case-insensitive support in apache_directive resources"
      path += "/directive[.='#{resource[:name]}'"
    end
    if resource[:args]
      resource[:args][0, resource[:args_params].to_i].each_with_index do |a, i|
        path += " and arg[#{i+1}]='#{a}'"
      end
    end
    path += ']'
    path
  end

  confine :feature => :augeas

  def self.instances
    augopen do |aug|
      aug.match('$target//directive').map do |spath|
        # Find path
        context = spath.slice("/files#{target}".length+1..-1).sub(%r{/?directive.*}, '')
        args = aug.match("#{spath}/arg").map do |apath|
          aug.get(apath)
        end
        new({
          :name        => aug.get(spath),
          :ensure      => :present,
          :args        => args,
          :context     => context,
          :args_params => 0
        })
      end
    end
  end

  def create
    augopen! do |aug|
      top_path = '$target'
      top_path += "/#{resource[:context]}" unless resource[:context].empty?
      last_path = "#{top_path}/directive[.='#{resource[:name]}'][last()]"
      if aug.match(last_path).empty?
        aug.clear("#{top_path}/directive[last()+1]") 
      else
        # Prefer to insert the new node after the last directive with the same name
        aug.insert(last_path, 'directive', false)
      end

      # The new node is the only directive without a value
      aug.defvar('new', "#{top_path}/directive[.='']")
      aug.set('$new', resource[:name])
      resource[:args].each_with_index do |a,i|
        aug.set("$new/arg[#{i+1}]", a)
      end
    end
  end

  def args
    augopen do |aug|
      aug.match('$resource[last()]/arg').map do |apath|
        aug.get(apath)
      end
    end
  end

  def args=(args)
    augopen! do |aug|
      aug.rm("#{resource_path}[position()!=last()]")
      setvars(aug)
      # Remove all options and replace them
      aug.rm('$resource/arg')
      args.each do |a|
        aug.set("$resource/arg[.='#{a}']", a)
      end
    end
  end
end
