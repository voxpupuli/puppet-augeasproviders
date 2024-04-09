# augeasproviders: alternative Augeas-based providers for Puppet


[![License](https://img.shields.io/github/license/voxpupuli/puppet-augeasproviders.svg)](https://github.com/voxpupuli/puppet-augeasproviders/blob/master/LICENSE)
[![Puppet Forge Version](http://img.shields.io/puppetforge/v/puppet/augeasproviders.svg)](https://forge.puppetlabs.com/puppet/augeasproviders)
[![Puppet Forge Downloads](http://img.shields.io/puppetforge/dt/puppet/augeasproviders.svg)](https://forge.puppetlabs.com/puppet/augeasproviders)
[![Build Status](https://github.com/voxpupuli/puppet-augeasproviders/workflows/CI/badge.svg)](https://github.com/voxpupuli/puppet-augeasproviders/actions?query=workflow%3ACI)
[![Donated by Herculesteam](https://img.shields.io/badge/donated%20by-herculesteam-fb7047.svg)](#transfer-notice)

# Features

This module provides is a meta module which gathers all official augeasproviders
modules as dependencies. 
Augeasproviders modules provide alternative Augeas-based providers for Puppet
providers around config files, using the Augeas configuration library to read
and modify them.

The advantage of using Augeas over the default Puppet `parsedfile`
implementations is that Augeas will go to great lengths to preserve file
formatting and comments, while also failing safely when needed.

## Requirements

Ensure both Augeas and ruby-augeas 0.3.0+ bindings are installed and working as
normal.

See [Puppet/Augeas pre-requisites](http://docs.puppetlabs.com/guides/augeas.html#pre-requisites).

## Classes

### augeasproviders::instances

This class allows the types provided by this module to be defined using the classes' parameters or top-scope variables.

**NOTE**: The classes' parameters take presedence over the top-scope variables.

Set the sysctl entry *net.ipv4.ip_forward* to *1*:

    class { 'augeasproviders::instances':
      sysctl_hash => { 'net.ipv4.ip_forward' => { 'value' => '1' } },
    }

The following example is the same as above but using a top-scope variable.

    node 'foo.example.com' {
      $augeasproviders_sysctl_hash = {
        'net.ipv4.ip_forward' => { 'value' => '1' },
      }
      
      include augeasproviders::instances
    }

#### Parameters

#####`TYPE`_hash

All types have a `TYPE`_hash parameter, where `TYPE` is the resource type.  These parameters accept a Hash to define that type's resources.

#####`resource_defaults`

A Hash that contains the default values used to create each resource.  See *manifests/params.pp* for the format used.

#### Variables

#####augeasproviders\_`TYPE`\_hash

All types have a augeasproviders\_`TYPE`\_hash variable, where `TYPE` is the resource type.  These variables accept a Hash to define that type's resources.

## Development documentation

See docs/ (run `make`) or [augeasproviders.com](http://augeasproviders.com/documentation/).

## Issues

Please file any issues or suggestions [on GitHub](https://github.com/voxpupuli/augeasproviders/issues).

## Supported OS

See [metadata.json](metadata.json) for supported OS versions.

## Dependencies

See [metadata.json](metadata.json) for dependencies.

## Puppet

The supported Puppet versions are listed in the [metadata.json](metadata.json)

## REFERENCES

Please see [REFERENCE.md](https://github.com/voxpupuli/puppet-augeasproviders/blob/master/REFERENCE.md) for more details.

## Contributing

Please report bugs and feature request using [GitHub issue tracker](https://github.com/voxpupuli/puppet-augeasproviders/issues).

For pull requests, it is very much appreciated to check your Puppet manifest
with [puppet-lint](https://github.com/puppetlabs/puppet-lint/) to follow the recommended Puppet style guidelines from the
[Puppet Labs style guide](https://www.puppet.com/docs/puppet/latest/style_guide.html).

## Transfer Notice

This plugin was originally authored by [Hercules Team](https://github.com/hercules-team).
The maintainer preferred that Puppet Community take ownership of the module for future improvement and maintenance.
Existing pull requests and issues were transferred over, please fork and continue to contribute here instead of Hercules Team.
