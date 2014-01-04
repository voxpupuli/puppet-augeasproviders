# Developing Puppet providers with `augeasproviders`

The `augeasproviders` library is a helper Ruby library to write Puppet providers allowing to manage files in parts, using Augeas.

This page describes the steps to create a provider using the `augeasproviders` API.


## Puppet type

The first thing you need is a Puppet type. It could be an existing type or a new type.

Whether you use an existing type or create a new one, the type should:

* be ensurable
* have a `target` parameter, specifying which file to manage.


## Making use of the library in your provider

The first thing you need to do is to load the `AugeasProviders::Provider` module in your provider code.

First, add a `require` statement on the library at the top of your provider file:

    require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Then, include the module in your provider declaration, for example:

    Puppet::Type.type(:my_type).provide(:augeas) do
      desc "Uses Augeas API to update my file"
    
      include AugeasProviders::Provider


## Declaring the default target

You can declare the default target for your provider by using the `default_file` method:

    default_file do
      "/path/to/my/file"
    end

This method takes a block which is interpreted when the default file is needed. Consequently, you can use code in the block, basing yourself on informations such as facts (using the `facter` API) to determine the default file.

The default file path will be used to declare a `$target` Augeas variable, which you can then use in your Augeas paths whenever needed.


## Declaring the lens to use

The next thing `augeasproviders` needs to know if the lens to use on this file. You can declare it with the `lens` method:

    lens do
      "MyFile.lns"
    end

Again, the block is interpreted down the road so you can use code in this block.

In the event that you need information from the resource itself in order to determine which lens to use, the method can yield it to you. For example, if you have a `lens` parameter in your type, you can use:

    lens do |resource|
      resource[:lens]
    end
    

## Confining your provider

Since the `augeasproviders` library uses Augeas, it is safe to confine your provider so it is only considered by Puppet if the `augeas` feature is available. You can do this with:

    confine :feature => :augeas


## Declaring the resource path

The `augeasproviders` library can take care of automatically declaring some provider methods if you specify the path to your resource in the Augeas tree. In order to do that, use the `resource_path` method, which yields the resource. You should use the `$target` Augeas variable (set by the `default_file` method) to refer to the root of the file you are managing, for example:

    resource_path do |resource|
      "$target/#{resource[:name]}"
    end

Using the `resource_path` method will automatically declare two provider methods: 

* `exists?` (which checks if the resource path exists)
* `destroy` (which removes the resource path and saves the tree)

These two methods can be overridden in your provider if you need a more advanced behaviour.

The `resource_path` method is also used to define a `$resource` Augeas variable, which you can use in your Augeas expressions, alongside the `$target` variable.


## Manipulating the Augeas tree

When defining your provider methods, you will need to manipulate the Augeas tree. `augeasproviders` provides two useful methods for this: `augopen` and `augopen!`

The easiest way to use the `augopen` method is to pass it a block. It will then yield the Augeas handler to the block:

    augopen do |aug|
      aug.get('$resource')
    end

The `augopen` method will open Augeas with your file/lens combination alone (making it faster), safely manage Augeas errors, and close the Augeas handler at the end of the block.

If you need to perform a tree change with Augeas, the `augopen!` method behaves just like `augopen`, but saves the tree automatically:

    augopen! do |aug|
      aug.set('$resource', 'value')
    end

## Defining provider methods

One convenient way to declare a provider method which only calls Augeas to get or set in the tree is to use the `define_aug_method` or `define_aug_method!` methods:

    define_aug_method!(:destroy) do |aug, resource|
      aug.rm("$target/command[#{resource[:name]}]")
    end

Again, the `define_aug_method!` method will save the tree, while `define_aug_method` will not.



## Defining property accessors


