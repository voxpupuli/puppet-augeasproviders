# augeasproviders: alternative Augeas-based providers for Puppet

This module provides alternative providers for core Puppet types such as
`host` and `mailalias` using the Augeas configuration library.  It also adds
some of its own types for new functionality.

The advantage of using Augeas over the default Puppet `parsedfile`
implementations is that Augeas will go to great lengths to preserve file
formatting and comments, while also failing safely when needed.

These providers will hide *all* of the Augeas commands etc., you don't need to
know anything about Augeas to make use of it.

If you want to make changes to config files in your own way, you should use
the `augeas` type directly.  For more information about Augeas, see the
[web site](http://augeas.net) or the
[Puppet/Augeas](http://projects.puppetlabs.com/projects/puppet/wiki/Puppet_Augeas)
wiki page.

## Types and providers

The following builtin types have an Augeas-based provider implemented:

* `host`
* `mailalias`

The following other types have a provider implemented:

* `mounttab` from [puppetlabs-mount_providers](http://forge.puppetlabs.com/puppetlabs/mount_providers)

The module adds the following new types:

* `apache_directive` for udpating generic Apache HTTP Server configs
* `apache_setenv` for updating SetEnv entries in Apache HTTP Server configs
* `kernel_parameter` for adding kernel parameters to GRUB Legacy or GRUB 2 configs
* `nrpe_command` for setting command entries in Nagios NRPE's `nrpe.cfg`
* `pam` for files inside /etc/pam.d/
* `pg_hba` for PostgreSQL's `pg_hba.conf` entries
* `puppet_auth` for authentication rules in Puppet's `auth.conf`
* `shellvar` for shell variables in `/etc/sysconfig` or `/etc/default` etc.
* `sshd_config` for setting configuration entries in OpenSSH's `sshd_config`
* `sshd_config_subsystem` for setting subsystem entries in OpenSSH's `sshd_config`
* `sysctl` for entries inside Linux's sysctl.conf
* `syslog` for entries inside syslog.conf

Lots of examples are provided in the accompanying documentation (see
`docs/examples.html`) and are also published [on the web site](http://augeasproviders.com/documentation/examples.html).
If this is a git checkout, you will need to run `make` in docs/ to generate the
HTML pages.

Type documentation can be generated with `puppet doc -r type` or viewed on the
[Puppet Forge page](http://forge.puppetlabs.com/domcleal/augeasproviders).

For builtin types and mounttab, the default provider will automatically become
the `augeas` provider once the module is installed.  This can be changed back
to `parsed` where necessary.

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

## Requirements

Ensure both Augeas and ruby-augeas 0.3.0+ bindings are installed and working as
normal.

See [Puppet/Augeas pre-requisites](http://projects.puppetlabs.com/projects/puppet/wiki/Puppet_Augeas#Pre-requisites).

## Installing

On Puppet 2.7.14+, the module can be installed easily ([documentation](http://docs.puppetlabs.com/puppet/2.7/reference/modules_installing.html)):

    puppet module install domcleal/augeasproviders

You may see an error similar to this on Puppet 2.x ([#13858](http://projects.puppetlabs.com/issues/13858)):

    Error 400 on SERVER: Puppet::Parser::AST::Resource failed with error ArgumentError: Invalid resource type `kernel_parameter` at ...

Ensure the module is present in your puppetmaster's own environment (it doesn't
have to use it) and that the master has pluginsync enabled.  Run the agent on
the puppetmaster to cause the custom types to be synced to its local libdir
(`puppet master --configprint libdir`) and then restart the puppetmaster so it
loads them.

## Planned

The following builtin types have Augeas-based providers planned:

* `ssh_authorized_key`
* `port`, once [#5660](http://projects.puppetlabs.com/issues/5660) is done
* `yumrepo`, once [#8758](http://projects.puppetlabs.com/issues/8758) is done

Other ideas for new types are:

* `/etc/system` types

## Compatibility

### Puppet versions

Puppet Versions | 2.7 -> 3.4 | >= 3.4   |
:---------------|:----------:|:-------:|
shared handler  | no         | **yes** |

### Augeas versions

Augeas Versions           | 0.10.0  | 1.0.0   | 1.1.0   | 1.2.0   |
:-------------------------|:-------:|:-------:|:-------:|:-------:|
**FEATURES**              |
case-insensitive keys     | no      | **yes** | **yes** | **yes** |
**PROVIDERS**             |
apache\_directive         | **yes** | **yes** | **yes** | **yes** |
apache\_setenv            | **yes** | **yes** | **yes** | **yes** |
host                      | **yes** | **yes** | **yes** | **yes** |
kernel\_parameter (grub)  | **yes** | **yes** | **yes** | **yes** |
kernel\_parameter (grub2) | **yes** | **yes** | **yes** | **yes** |
mailalias                 | **yes** | **yes** | **yes** | **yes** |
mounttab (fstab)          | **yes** | **yes** | **yes** | **yes** |
mounttab (vfstab)         | no      | **yes** | **yes** | **yes** |
nrpe\_command             | **yes** | **yes** | **yes** | **yes** |
pg\_hba                   | no      | **yes** | **yes** | **yes** |
puppet\_auth              | no      | **yes** | **yes** | **yes** |
shellvar                  | **yes** | **yes** | **yes** | **yes** |
sshd\_config              | **yes** | **yes** | **yes** | **yes** |
sshd\_config\_subsystem   | **yes** | **yes** | **yes** | **yes** |
sysctl                    | **yes** | **yes** | **yes** | **yes** |
syslog (augeas)           | **yes** | **yes** | **yes** | **yes** |
syslog (rsyslog)          | no      | **yes** | **yes** | **yes** |



## Issues

Please file any issues or suggestions [on GitHub](https://github.com/hercules-team/augeasproviders/issues).
