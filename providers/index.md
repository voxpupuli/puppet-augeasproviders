---
layout: minimal
title: augeasproviders - Types and providers
---

# Types and providers

The following builtin types have an Augeas-based provider implemented:

* `host`
* `mailalias`

The following other types have a provider implemented:

* `mounttab` from [puppetlabs-mount_providers](http://forge.puppetlabs.com/puppetlabs/mount_providers)

The module adds the following new types:

* `apache_setenv` for updating SetEnv entries in Apache HTTP Server configs
* `kernel_parameter` for adding kernel parameters to GRUB Legacy or GRUB 2 configs
* `nrpe_command` for setting command entries in Nagios NRPE's `nrpe.cfg`
* `puppet_auth` for authentication rules in Puppet's `auth.conf`
* `shellvar` for shell variables in `/etc/sysconfig` or `/etc/default` etc.
* `sshd_config` for setting configuration entries in OpenSSH's `sshd_config`
* `sshd_config_subsystem` for setting subsystem entries in OpenSSH's `sshd_config`
* `sysctl` for entries inside Linux's sysctl.conf
* `syslog` for entries inside syslog.conf

See <a href="/documentation/examples.html">examples</a> of each type in use.

## Planned

The following builtin types have Augeas-based providers planned:

* `ssh_authorized_key`
* `port`, once [#5660](http://projects.puppetlabs.com/issues/5660) is done
* `yumrepo`, once [#8758](http://projects.puppetlabs.com/issues/8758) is done

Other ideas for new types are:

* `/etc/system` types

## Issues

Please file any issues or suggestions [on GitHub](https://github.com/hercules-team/augeasproviders/issues).
