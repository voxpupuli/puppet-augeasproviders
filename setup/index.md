---
layout: minimal
title: augeasproviders - Setting up
---

# Setting up

## Requirements

Ensure both Augeas and ruby-augeas 0.3.0+ bindings are installed and working as
normal.

See [Puppet/Augeas pre-requisites](http://docs.puppetlabs.com/guides/augeas.html#pre-requisites).

## Installing

On Puppet 2.7.14+, the module can be installed easily ([documentation](http://docs.puppetlabs.com/puppet/2.7/reference/modules_installing.html)):

    puppet module install herculesteam/augeasproviders

New types provided by augeasproviders can be used out of the box.  See the <a
href="/providers/">providers</a> page and `puppet doc -r type` output.

## Troubleshooting

You may see an error similar to this on Puppet 2.x ([#13858](http://projects.puppetlabs.com/issues/13858)):

    Error 400 on SERVER: Puppet::Parser::AST::Resource failed with error ArgumentError: Invalid resource type `kernel_parameter` at ...

Ensure the module is present in your puppetmaster's own environment (it doesn't
have to use it) and that the master has pluginsync enabled.  Run the agent on
the puppetmaster to cause the custom types to be synced to its local libdir
(`puppet master --configprint libdir`) and then restart the puppetmaster so it
loads them.

## Compatibility

### Puppet versions

Puppet Versions | 2.7 -> 3.4 | >= 3.4   |
:---------------|:----------:|:-------:|
compatibility   | **yes**    | **yes** |
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
