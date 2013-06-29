# Utilities for providers
#
# Copyright (c) 2012 Dominic Cleal
# Licensed under the Apache License, Version 2.0

require 'augeas' if Puppet.features.augeas?
require File.dirname(__FILE__) + '/../augeasproviders'

module AugeasProviders::Provider
  class << self
    attr_accessor :loadpath
  end

  def self.included(base)
    base.send(:extend, ClassMethods)
  end

  module ClassMethods
    def lens(resource = nil, &block)
      if block_given?
        @lens_block = block
      else
        fail 'Lens is not provided' unless @lens_block
        @lens_block.call(resource)
      end
    end

    def default_file(&block)
      @default_file_block = block
    end

    def resource_path(resource = nil, &block)
      if block_given?
        @resource_path_block = block
      else
        if @resource_path_block
          @resource_path_block.call(resource)
        else
          target(resource)
        end
      end
    end

    def target(resource = nil)
      file = @default_file_block.call if @default_file_block
      file = resource[:target] if resource and resource[:target]
      fail 'No target file given' if file.nil?
      file.chomp('/')
    end

    def augopen(resource = nil, &block)
      loadpath = AugeasProviders::Provider.loadpath
      file = target(resource)
      aug = nil
      begin
        aug = Augeas.open(nil, loadpath, Augeas::NO_MODL_AUTOLOAD)
        aug.transform(
          :lens => lens,
          :name => "AP",
          :incl => file,
          :excl => []
        )
        aug.load!

        if File.exist?(file) && aug.match("/files#{file}").empty?
          message = aug.get("/augeas/files#{file}/error/message")
          fail("Augeas didn't load #{file} with #{lens} from #{loadpath}: #{message}")
        end

        if block_given?
          block.call(aug, "/files#{file}")
        else
          aug
        end
      rescue
        if aug
          aug.close
          aug = nil
        end
        raise
      ensure
        aug.close if block_given? && aug
      end
    end

    def augsave!(aug)
      begin
        aug.save!
      rescue Augeas::Error
        errors = []
        aug.match("/augeas//error").each do |errnode|
          aug.match("#{errnode}/*").each do |subnode|
            subvalue = aug.get(subnode)
            errors << "#{subnode} = #{subvalue}"
          end
        end
        raise Augeas::Error, errors.join("\n")
      end
    end
  end

  def augopen(&block)
    self.class.augopen(self.resource, &block)
  end

  def augsave!(aug)
    self.class.augsave!(aug)
  end

  def resource_path
    self.class.resource_path(self.resource)
  end

  def target
    self.class.target(self.resource)
  end
end
