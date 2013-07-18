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
    # If `yield_resource` is set to true, the supplied `resource` will be passed
    # as a yieldparam to the block, after the `aug` handle. Any arguments passed
    # after `yield_resource` will be added as yieldparams to the block.
    #
    # @param [Puppet::Resource] resource resource being evaluated
    # @param [Boolean] autosave whether to call augsave! automatically after the block evaluation
    # @param [Boolean] yield_resource whether to send `resource` as a yieldparam
    # @param [Splat] *yield_params a splat of parameters to pass as yieldparams if `yield_resource` is true
    # @return [Augeas] Augeas handle if no block is given
    # @yield [aug, resource, *yield_params] block that uses the Augeas handle
    # @yieldparam [Augeas] aug open Augeas handle
    # @yieldparam [Puppet::Resource] resource the supplied Puppet resource, passed if `yield_resource` is set to true
    # @yieldparam [Splat] *yield_params a splat of additional arguments sent to the block, if `yield_resource` is set to true
    # @raise [Puppet::Error] if Augeas did not load the file
    # @api public
    def augopen(resource = nil, autosave = false, yield_resource = false, *yield_params, &block)
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
          if yield_resource
            block.call(aug, resource, *yield_params)
          else
            block.call(aug)
          end
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

    # Opens Augeas and returns a handle to use.  It loads only the file
    # for the current Puppet resource using {AugeasProviders::Provider::ClassMethods#lens}.
    # #augsave! is called after the block is evaluated.
    #
    # If called with a block, this will be yielded to and the Augeas handle
    # closed after the block has executed.  Otherwise, the handle will be
    # returned and the caller is responsible for closing it to free resources.
    #
    # If `yield_resource` is set to true, the supplied `resource` will be passed
    # as a yieldparam to the block, after the `aug` handle. Any arguments passed
    # after `yield_resource` will be added as yieldparams to the block.
    #
    # @param [Puppet::Resource] resource resource being evaluated
    # @param [Boolean] yield_resource whether to send `resource` as a yieldparam
    # @param [Splat] *yield_params a splat of parameters to pass as yieldparams if `yield_resource` is true
    # @return [Augeas] Augeas handle if no block is given
    # @yield [aug, resource, *yield_params] block that uses the Augeas handle
    # @yieldparam [Augeas] aug open Augeas handle
    # @yieldparam [Puppet::Resource] resource the supplied Puppet resource, passed if `yield_resource` is set to true
    # @yieldparam [Splat] *yield_params a splat of additional arguments sent to the block, if `yield_resource` is set to true
    # @raise [Puppet::Error] if Augeas did not load the file
    # @api public
    def augopen!(resource = nil, yield_resource = false, *args, &block)
      augopen(resource, true, yield_resource, *args, &block)
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

    # Define a method using augopen
    #
    # @param [Symbol] meth the name of the method to create
    # @yield [aug, resource, *args] block that uses the Augeas handle
    # @yieldparam [Augeas] aug open Augeas handle
    # @yieldparam [Puppet::Resource] resource the supplied Puppet resource
    # @yieldparam [Splat] *args a splat of additional arguments sent to the block
    # @api public
    def define_augmethod(meth, &block)
      define_method(meth) do |*args|
        # We are calling the resource's augopen here, not the class
        augopen(false, true, *args, &block)
      end
    end
  
    # Define a method using augopen!
    #
    # @param [Symbol] meth the name of the method to create
    # @yield [aug, resource, *args] block that uses the Augeas handle
    # @yieldparam [Augeas] aug open Augeas handle
    # @yieldparam [Puppet::Resource] resource the supplied Puppet resource
    # @yieldparam [Splat] *args a splat of additional arguments sent to the block
    # @api public
    def define_augmethod!(meth, &block)
      define_method(meth) do |*args|
        # We are calling the resource's augopen! here, not the class
        augopen!(true, *args, &block)
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

    # Wrapper around aug.label for older versions of Augeas
    # and values not found in the tree.
    #
    # @param [Augeas] aug Augeas handler
    # @param [String] path expression to get the label from
    # @return [String] label of the given path
    # @api public
    def path_label(aug, path)
      if aug.respond_to? :label
        label = aug.label(path)
      end

      # Fallback
      label || path.split("/")[-1].split("[")[0]
    end

    # Automatically quote a value
    #
    # @param [String] value the value to quote
    # @param [String] oldvalue the optional old value, used to auto-detect existing quoting
    # @return [String] the quoted value
    # @api public
    def quoteit(value, resource = nil, oldvalue = nil)
      oldquote = readquote oldvalue
  
      if resource and resource.parameters.include? :quoted
        quote = resource[:quoted]
      else
        quote = :auto
      end
  
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
  
    # Detect what type of quoting a value uses
    #
    # @param [String] value the value to be analyzed
    # @return [Symbol] the type of quoting used (:double, :single or nil)
    # @api public
    def readquote(value)
      if value =~ /^(["'])(.*)(?:\1)$/
        case $1
        when '"' then :double
        when "'" then :single
        else nil end
      else
        nil
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
          @resource_path_block.call(resource)
        else
          "#{target(resource)}/#{resource[:name]}"
        end
      end
    end

    # Sets useful Augeas variables for the session.
    #
    # * `$target` points to the root of the target file
    # * `$resource` points to path defined by #resource_path
    #
    # It also sets `/augeas/context` to the target file so
    # relative paths can be used, before the variables are set.
    #
    # If supplied with a resource, it will be used to determine the
    # path to the used file.
    #
    # @param [Augeas] aug Augeas handle
    # @param [Puppet::Resource] resource resource being evaluated
    # @see #resource_path
    # @api public
    def setvars(aug, resource = nil)
      aug.set('/augeas/context', "/files#{target(resource)}")
      aug.defnode('target', "/files#{target(resource)}", nil)
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

    # Automatically unquote a value
    # 
    # @param [String] value the value to unquote
    # @return [String] the unquoted value
    # @api public
    def unquoteit(value)
      if value =~ /^(["'])(.*)(?:\1)$/
        $2
      else
        value
      end
    end
  end

  # Opens Augeas and returns a handle to use.  It loads only the file
  # for the current Puppet resource using {AugeasProviders::Provider::ClassMethods#lens}.
  #
  # If called with a block, this will be yielded to and the Augeas handle
  # closed after the block has executed.  Otherwise, the handle will be
  # returned and the caller is responsible for closing it to free resources.
  #
  # If `yield_resource` is set to true, the supplied `resource` will be passed
  # as a yieldparam to the block, after the `aug` handle. Any arguments passed
  # after `yield_resource` will be added as yieldparams to the block.
  #
  # @return [Augeas] Augeas handle if no block is given
  # @yield [aug, resource, *yield_params] block that uses the Augeas handle
  # @yieldparam [Augeas] aug open Augeas handle
  # @yieldparam [Puppet::Resource] resource the supplied Puppet resource, passed if `yield_resource` is set to true
  # @yieldparam [Splat] *yield_params a splat of additional arguments sent to the block, if `yield_resource` is set to true
  # @raise [Puppet::Error] if Augeas did not load the file
  # @api public
  def augopen(autosave = false, yield_resource = false, *yield_params, &block)
    self.class.augopen(self.resource, autosave, yield_resource, *yield_params, &block)
  end

  # Opens Augeas and returns a handle to use.  It loads only the file
  # for the current Puppet resource using {AugeasProviders::Provider::ClassMethods#lens}.
  # #augsave! is called after the block is evaluated.
  #
  # If called with a block, this will be yielded to and the Augeas handle
  # closed after the block has executed.  Otherwise, the handle will be
  # returned and the caller is responsible for closing it to free resources.
  #
  # @return [Augeas] Augeas handle if no block is given
  # @yield [aug, resource, *yield_params] block that uses the Augeas handle
  # @yieldparam [Augeas] aug open Augeas handle
  # @yieldparam [Puppet::Resource] resource the supplied Puppet resource, passed if `yield_resource` is set to true
  # @yieldparam [Splat] *yield_params a splat of additional arguments sent to the block, if `yield_resource` is set to true
  # @raise [Puppet::Error] if Augeas did not load the file
  # @api public
  def augopen!(yield_resource = false, *yield_params, &block)
    self.class.augopen!(self.resource, yield_resource, *yield_params, &block)
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

  # Wrapper around Augeas#label for older versions of Augeas
  #
  # @param [Augeas] aug Augeas handler
  # @param [String] path expression to get the label from
  # @return [String] label of the given path
  # @api public
  def path_label(aug, path)
    self.class.path_label(aug, path)
  end

  # Automatically quote a value
  #
  # @param [String] value the value to quote
  # @param [String] oldvalue the optional old value, used to auto-detect existing quoting
  # @return [String] the quoted value
  # @api public
  def quoteit(value, oldvalue = nil)
    self.class.quoteit(value, self.resource, oldvalue)
  end

  # Detect what type of quoting a value uses
  #
  # @param [String] value the value to be analyzed
  # @return [Symbol] the type of quoting used (:double, :single or nil)
  # @api public
  def readquote(value)
    self.class.readquote(value)
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

  # Sets useful Augeas variables for the session:
  #
  # * `$target` points to the root of the target file
  # * `$resource` points to path defined by #resource_path
  #
  # It also sets `/augeas/context` to the target file so
  # relative paths can be used, before the variables are set.
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

  # Automatically unquote a value
  # 
  # @param [String] value the value to unquote
  # @return [String] the unquoted value
  # @api public
  def unquoteit(value)
    self.class.unquoteit(value)
  end

  # Default method to determine the existence of a resource
  # can be overridden if necessary
  def exists?
    augopen do |aug|
      not aug.match('$resource').empty?
    end
  end

  # Default method to destroy a resource
  # can be overridden if necessary
  def destroy
    augopen(true) do |aug|
      aug.rm('$resource')
    end
  end
end
