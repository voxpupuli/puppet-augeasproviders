# Utilities for providers
#
# Copyright (c) 2012 Dominic Cleal
# Licensed under the Apache License, Version 2.0

require 'augeas' if Puppet.features.augeas?
require File.dirname(__FILE__) + '/../augeasproviders'

# Mixin to add Augeas-related helpers to Puppet providers.
#
# Handles basics such as opening, accessing and saving changes via an Augeas
# handle, plus standard configuration from a Puppet resource (e.g. the `target`
# parameter).
#
# To use, include in the provider:
#
#     Puppet::Type.type(:example).provide(:augeas) do
#       include AugeasProviders::Provider
#       # [..]
#     end
#
# @api public
module AugeasProviders::Provider
  class << self
    # Override Augeas' loadpath, usually for testing with a separate Augeas
    # checkout.
    # @api private
    attr_accessor :loadpath
  end

  def self.included(base)
    base.send(:extend, ClassMethods)
  end

  # Class methods automatically added to a Puppet provider by including the
  # {AugeasProviders::Provider} mixin.
  #
  # @api public
  module ClassMethods
    # Opens Augeas and returns a handle to use.  It loads only the file
    # identified by {#target} (and the supplied `resource`) using {#lens}.
    #
    # If called with a block, this will be yielded to and the Augeas handle
    # closed after the block has executed.  Otherwise, the handle will be
    # returned and the caller is responsible for closing it to free resources.
    #
    # @param [Puppet::Resource] resource resource being evaluated
    # @return [Augeas] Augeas handle if no block is given
    # @yield [aug,path] block that uses the Augeas handle
    # @yieldparam [Augeas] aug open Augeas handle
    # @yieldparam [String] path path expression representing the file being managed
    # @raise [Puppet::Error] if Augeas did not load the file
    # @api public
    def augopen(resource = nil, autosave = false, &block)
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
          setvars(aug, resource)
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
        augsave!(aug) if block_given? && autosave
        aug.close if block_given? && aug
      end
    end

    # Saves all changes made in the current Augeas handle and checks for any
    # errors while doing so.
    #
    # @param [Augeas] aug open Augeas handle
    # @raise [Augeas::Error] if saving fails
    # @api public
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

    # Setter for the default file path managed by the provider.
    #
    # Takes a block to store, but doesn't yield.  Will be called when it's
    # needed.
    #
    # @yield block that identifies the default file path managed by the provider
    # @yieldreturn [String] default file path
    # @api public
    def default_file(&block)
      @default_file_block = block
    end

    # Getter and setter for the Augeas lens used for this provider.
    #
    # When called with a block, will only store the block - it doesn't yield.
    #
    # When called without a block, expects `resource` parameter which is
    # passed into the block, which returns the lens to be used.
    #
    # @param resource [Puppet::Resource] required for getter, resource being evaluated
    # @yield [resource] block that identifies the lens to use
    # @yieldparam [Puppet::Resource] resource resource being evaluted
    # @yieldreturn [String] Augeas lens to use, e.g. `'Hosts.lns'`
    # @return [String] Augeas lens to use, e.g. `'Hosts.lns'`
    # @raise [Puppet::Error] if no block has been set when getting
    # @api public
    def lens(resource = nil, &block)
      if block_given?
        @lens_block = block
      else
        fail 'Lens is not provided' unless @lens_block
        @lens_block.call(resource)
      end
    end

    # Getter and setter for the Augeas path expression representing an
    # individual resource inside a file, that's managed by this provider.
    #
    # When called with a block, will only store the block - it doesn't yield.
    # The block is later used to generate the path expression.
    #
    # When called without a block, expects `resource` parameter which is
    # passed into the block, which returns the path expression representing
    # the supplied resource.
    #
    # If no block has already been set, it returns the path expression
    # representing the top-level of the file.
    #
    # @param resource [Puppet::Resource] required for getter, resource being evaluated
    # @yield [resource] block that identifies the path expression
    # @yieldparam [Puppet::Resource] resource resource being evaluted
    # @yieldreturn [String] Augeas path expression, e.g. `'/files/etc/hosts/1'`
    # @return [String] Augeas path expression to use, e.g. `'/files/etc/hosts/1'`
    # @raise [Puppet::Error] if no default file block is set and no resource is passed
    # @see AugeasProviders::Provider#resource_path
    # @see #target
    # @api public
    def resource_path(resource = nil, &block)
      if block_given?
        @resource_path_block = block
      else
        if @resource_path_block
          path = "/files#{target(resource)}"
          @resource_path_block.call(resource, path)
        else
          "#{target(resource)}/#{resource[:name]}"
        end
      end
    end

    # Sets useful Augeas variables for the session.
    #
    # If supplied with a resource, it will be used to determine the
    # path to the used file.
    #
    # @param [Augeas] aug Augeas handle
    # @param [Puppet::Resource] resource resource being evaluated
    # @see #resource_path
    # @api public
    def setvars(aug, resource = nil)
      aug.defvar('target', "/files#{target(resource)}")
      aug.defvar('resource', resource_path(resource)) if resource
    end

    # Gets the path expression representing the file being managed.
    #
    # If supplied with a resource, this will represent the file identified by
    # the resource, else the default file that the provider manages. 
    #
    # @param [Puppet::Resource] resource resource being evaluated
    # @return [String] path expression representing the file being managed
    # @raise [Puppet::Error] if no default block is set and no resource is passed
    # @see AugeasProviders::Provider#target
    # @see #resource_path
    # @api public
    def target(resource = nil)
      file = @default_file_block.call if @default_file_block
      file = resource[:target] if resource and resource[:target]
      fail 'No target file given' if file.nil?
      file.chomp('/')
    end
  end

  # Opens Augeas and returns a handle to use.  It loads only the file
  # for the current Puppet resource using {AugeasProviders::Provider::ClassMethods#lens}.
  #
  # If called with a block, this will be yielded to and the Augeas handle
  # closed after the block has executed.  Otherwise, the handle will be
  # returned and the caller is responsible for closing it to free resources.
  #
  # @return [Augeas] Augeas handle if no block is given
  # @yield [aug,path] block that uses the Augeas handle
  # @yieldparam [Augeas] aug open Augeas handle
  # @yieldparam [String] path path expression representing the file being managed
  # @raise [Puppet::Error] if Augeas did not load the file
  # @api public
  def augopen(autosave = false, &block)
    self.class.augopen(self.resource, autosave, &block)
  end

  # Saves all changes made in the current Augeas handle and checks for any
  # errors while doing so.
  #
  # @param [Augeas] aug open Augeas handle
  # @raise [Augeas::Error] if saving fails
  # @api public
  def augsave!(aug)
    self.class.augsave!(aug)
  end

  # Gets the Augeas path expression representing the individual resource inside
  # the file, that represents the current Puppet resource.
  #
  # If no block was set by the provider's class method, it returns the path
  # expression representing the top-level of the file.
  #
  # @return [String] Augeas path expression to use, e.g. `'/files/etc/hosts/1'`
  # @see AugeasProviders::Provider::ClassMethods#resource_path
  # @see #target
  # @api public
  def resource_path
    self.class.resource_path(self.resource)
  end

  # Sets useful Augeas variables for the session.
  #
  # If supplied with a resource, it will be used to determine the
  # path to the used file.
  #
  # @param [Augeas] aug Augeas handle
  # @param [Puppet::Resource] resource resource being evaluated
  # @see #resource_path
  # @api public
  def setvars(aug)
    self.class.setvars(aug, self.resource)
  end

  # Gets the path expression representing the file being managed for the
  # current Puppet resource.
  #
  # @return [String] path expression representing the file being managed
  # @see AugeasProviders::Provider::ClassMethods#target
  # @see #resource_path
  # @api public
  def target
    self.class.target(self.resource)
  end

  # Default method to determine the existence of a resource
  # can be overridden if necessary
  def exists?
    augopen do |aug, path|
      not aug.match('$resource').empty?
    end
  end

  # Default method to destroy a resource
  # can be overridden if necessary
  def destroy
    augopen(true) do |aug, path|
      aug.rm('$resource')
    end
  end
end
