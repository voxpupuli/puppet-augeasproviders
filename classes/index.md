---
layout: minimal
title: augeasproviders - Puppet classes
---

# Puppet classes

## augeasproviders::instances

This class allows the types provided by this module to be defined using the
classes' parameters or top-scope variables.

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

### Parameters

####`TYPE`_hash

All types have a `TYPE`_hash parameter, where `TYPE` is the resource type.
These parameters accept a Hash to define that type's resources.

####`resource_defaults`

A Hash that contains the default values used to create each resource.  See
*manifests/params.pp* for the format used.

### Variables

####augeasproviders\_`TYPE`\_hash

All types have a augeasproviders\_`TYPE`\_hash variable, where `TYPE` is the
resource type.  These variables accept a Hash to define that type's resources.
