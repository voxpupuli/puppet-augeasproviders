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

## Using augeasproviders

For builtin types, change the provider on individual resources to `augeas`:

<pre>
host { "example.com":
  ensure   => present,
  ip       => "10.1.2.3",
  provider => "augeas",
}
</pre>

Or change the [resource
defaults](http://docs.puppetlabs.com/puppet/2.7/reference/lang_defaults.html)
globally or in a single scope for the types needed from the list below:

<pre>
Host {
  provider => "augeas",
}
</pre>

New types provided by augeasproviders can be used out of the box.  See the list
below and `puppet doc -r type` output.

## Types and providers

The following builtin types have an Augeas-based provider implemented:

  * `host`
  * `mailalias`

The following other types have a provider implemented:

  * `mounttab` from [puppetlabs-mount_providers](http://forge.puppetlabs.com/puppetlabs/mount_providers)

The module adds the following new types:

  * `sshd_config` for setting configuration entries in OpenSSH's `sshd_config`
  * `sshd_config_subsystem` for setting subsystem entries in OpenSSH's `sshd_config`
  * `sysctl` for entries inside Linux's sysctl.conf
  * `syslog` for entries inside syslog.conf

## Requirements

Ensure both Augeas and ruby-augeas 0.3.0+ bindings are installed and working as
normal.

See [Puppet/Augeas pre-requisites](http://projects.puppetlabs.com/projects/puppet/wiki/Puppet_Augeas#Pre-requisites).

## Planned

The following builtin types have Augeas-based providers planned:

  * `ssh_authorized_key`
  * `port`, once [#5660](http://projects.puppetlabs.com/issues/5660) is done
  * `yumrepo`, once [#8758](http://projects.puppetlabs.com/issues/8758) is done

Other ideas for new types are:

  * `kernel_parameter` with bootloader providers
  * `/etc/system` types

## Issues

Please file any issues or suggestions on GitHub:
  https://github.com/domcleal/augeasproviders/issues
