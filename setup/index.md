---
layout: minimal
title: augeasproviders - Setting up
---

# Setting up

## Requirements

Ensure both Augeas and ruby-augeas 0.3.0+ bindings are installed and working as
normal.

See [Puppet/Augeas pre-requisites](http://projects.puppetlabs.com/projects/puppet/wiki/Puppet_Augeas#Pre-requisites).

## Installing

On Puppet 2.7.14+, the module can be installed easily ([documentation](http://docs.puppetlabs.com/puppet/2.7/reference/modules_installing.html)):

    puppet module install domcleal/augeasproviders

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
