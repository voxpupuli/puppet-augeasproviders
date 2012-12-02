---
layout: minimal
title: augeasproviders - Examples
---

# Manifest examples

Examples are given below for each of the providers and custom types in
`augeasproviders`.

* [host provider](#host_provider)
* [kernel_parameter provider](#kernel_parameter_provider)
* [mailalias provider](#mailalias_provider)
* [mounttab provider](#mounttab_provider)
* [nrpe_command provider](#nrpe_command_provider)
* [sshd_config provider](#sshd_config_provider)
* [sshd_config_subsystem provider](#sshd_config_subsystem_provider)
* [sysctl provider](#sysctl_provider)
* [syslog provider](#syslog_provider)

## host provider

This is a provider for a type distributed in Puppet core: [host type
reference](http://docs.puppetlabs.com/references/stable/type.html#host).

The provider needs to be explicitly given as `augeas` to use `augeasproviders`.

The `comment` parameter is only supported on Puppet 2.7 and higher.

### manage simple entry

    host { "example":
      ensure   => present,
      ip       => "192.168.1.1",
      provider => augeas,
    }

### manage entry with aliases and comment

    host { "example":
      ensure       => present,
      ip           => "192.168.1.1",
      host_aliases => [ "foo-a", "foo-b" ],
      comment      => "test",
      provider     => augeas,
    }

### manage entry in another location

    host { "example":
      ensure   => present,
      ip       => "192.168.1.1",
      target   => "/etc/anotherhosts",
      provider => augeas,
    }

### delete entry

    host { "iridium":
      ensure   => absent,
      provider => augeas,
    }

### remove aliases

    host { "iridium":
      ensure       => present,
      host_aliases => [],
      provider     => augeas,
    }

### remove comment

    host { "argon":
      ensure   => present,
      comment  => "",
      provider => augeas,
    }
## kernel_parameter provider

This is a custom type and provider supplied by `augeasproviders`.  It supports
both GRUB Legacy (0.9x) and GRUB 2 configurations.

### manage parameter without value

    kernel_parameter { "quiet":
      ensure => present,
    }

### manage parameter with value

    kernel_parameter { "elevator":
      ensure  => present,
      value   => "deadline",
    }

### manage parameter with multiple values

    kernel_parameter { "rd_LVM_LV":
      ensure  => present,
      value   => ["vg/lvroot", "vg/lvvar"],
    }

### manage parameter on certain boot types

Bootmode defaults to "all", so settings are applied for all boot types usually.

Apply only to normal boots:

    kernel_parameter { "quiet":
      ensure   => present,
      bootmode => "normal",
    }

Only recovery mode boots (unsupported with GRUB 2):

    kernel_parameter { "quiet":
      ensure   => present,
      bootmode => "recovery",
    }

### delete entry

    kernel_parameter { "rhgb":
      ensure => absent,
    }

### manage parameter in another config location

    kernel_parameter { "elevator":
      ensure => present,
      value  => "deadline",
      target => "/mnt/boot/grub/menu.lst",
    }
## mailalias provider

This is a provider for a type distributed in Puppet core: [mailalias type
reference](http://docs.puppetlabs.com/references/stable/type.html#mailalias).

The provider needs to be explicitly given as `augeas` to use `augeasproviders`.

### manage simple entry

    mailalias { "example":
      ensure    => present,
      recipient => "bar",
      provider  => augeas,
    }

### manage entry with multiple recipients

    mailalias { "example":
      ensure    => present,
      recipient => [ "fred", "bob" ],
      provider  => augeas,
    }

### manage entry in another location

    mailalias { "example":
      ensure    => present,
      recipient => "bar",
      target    => "/etc/anotheraliases",
      provider  => augeas,
    }

### delete entry

    mailalias { "mailer-daemon":
      ensure   => absent,
      provider => augeas,
    }
## mounttab provider

This is a provider for a type distributed in the [puppetlabs-mount_providers
module](http://forge.puppetlabs.com/puppetlabs/mount_providers).

The provider needs to be explicitly given as `augeas` to use `augeasproviders`.

If editing a vfstab entry, slightly different options need to be passed
compared to a fstab entry.

### manage simple fstab entry

    mounttab { "/mnt":
      ensure   => present,
      device   => "/dev/myvg/mytest",
      fstype   => "ext4",
      options  => "defaults",
      provider => augeas,
    }

### manage full fstab entry

    mounttab { "/mnt":
      ensure   => present,
      device   => "/dev/myvg/mytest",
      fstype   => "ext4",
      options  => ["nosuid", "uid=12345"],
      dump     => "1",
      pass     => "2",
      provider => augeas,
    }

### manage fstab entry with default options

    mounttab { "/mnt":
      ensure   => present,
      device   => "/dev/myvg/mytest",
      fstype   => "ext4",
      provider => augeas,
    }

### delete fstab entry

    mounttab { "/":
      ensure   => absent,
      provider => augeas,
    }

### manage entry in another fstab location

    mounttab { "/home":
      ensure   => present,
      device   => "/dev/myvg/mytest",
      target   => "/etc/anotherfstab",
      provider => augeas
    }

### manage device in fstab entry only

    mounttab { "/home":
      ensure   => present,
      device   => "/dev/myvg/mytest",
      provider => augeas
    }

Note: dump and pass are both changing unless explicitly specified, see issue
[#16122](http://projects.puppetlabs.com/issues/16122).

### manage fstype in fstab entry only

    mounttab { "/home":
      ensure   => present,
      fstype   => "btrfs",
      provider => augeas,
    }

### manage options in fstab entry only

    mounttab { "/home":
      ensure   => present,
      options  => "nosuid",
      provider => augeas,
    }

### manage complex options in fstab entry only

    mounttab { "/home":
      ensure   => present,
      options  => [
        "nosuid",
        "uid=12345",
        'rootcontext="system_u:object_r:tmpfs_t:s0"',
      ],
      provider => augeas,
    }

### remove options from fstab entry

    mounttab { "/home":
      ensure   => present,
      options  => [],
      provider => augeas,
    }

### manage simple vfstab entry

    mounttab { "/mnt":
      ensure   => present,
      device   => "/dev/dsk/c1t1d1s1",
      fstype   => "ufs",
      atboot   => "yes",
      provider => augeas,
    }

### manage full vfstab entry

    mounttab { "/mnt":
      ensure      => present,
      device      => "/dev/dsk/c1t1d1s1",
      blockdevice => "/dev/foo/c1t1d1s1",
      fstype      => "ufs",
      pass        => "2",
      atboot      => "yes",
      options     => [ "nosuid", "nodev" ],
      provider    => augeas,
    }

### manage vfstab entry with default options

    mounttab { "/mnt":
      ensure   => present,
      device   => "/dev/myvg/mytest",
      fstype   => "ext4",
      provider => augeas,
    }

### delete vfstab entry

    mounttab { "/":
      ensure   => absent,
      provider => augeas,
    }

### remove options from vfstab entry

    mounttab { "/home":
      ensure   => present,
      options  => [],
      provider => augeas,
    }
## nrpe_command provider

This is a custom type and provider supplied by `augeasproviders`.

### manage entry

    nrpe_command { "check_spec_test":
      ensure  => present,
      command => "/usr/bin/check_my_thing -p 'some command with \"multiple [types]\" of quotes' -x and-stuff",
    }

### delete entry

    nrpe_command { "check_test":
      ensure => absent,
    }
## sshd_config provider

This is a custom type and provider supplied by `augeasproviders`.

### manage simple entry

    sshd_config { "PermitRootLogin":
      ensure => present,
      value  => "yes",
    }

### manage array entry

    sshd_config { "AllowGroups":
      ensure => present,
      value  => ["sshgroups", "admins"],
    }

### manage entry in a Match block

    sshd_config { "X11Forwarding":
      ensure    => present,
      condition => "Host foo User root",
      value     => "yes",
    }

    sshd_config { "AllowAgentForwarding":
      ensure    => present,
      condition => "Host *.example.net",
      value     => "yes",
    }

### delete entry

    sshd_config { "PermitRootLogin":
      ensure => absent,
    }

    sshd_config { "AllowAgentForwarding":
      ensure    => absent,
      condition => "Host *.example.net User *",
    }

### manage entry in another sshd_config location

    sshd_config { "PermitRootLogin":
      ensure => present,
      value  => "yes",
      target => "/etc/ssh/another_sshd_config",
    }
## sshd_config_subsystem provider

This is a custom type and provider supplied by `augeasproviders`.

### manage entry

    sshd_config_subsystem { "sftp":
      ensure  => present,
      command => "/usr/lib/openssh/sftp-server",
    }

### delete entry

    sshd_config_subsystem { "sftp":
      ensure => absent,
    }

### manage entry in another sshd_config location

    sshd_config_subsystem { "sftp":
      ensure  => present,
      command => "/usr/lib/openssh/sftp-server",
      target  => "/etc/ssh/another_sshd_config",
    }
## sysctl provider

This is a custom type and provider supplied by `augeasproviders`.

### manage simple entry

    sysctl { "net.ipv4.ip_forward":
      ensure => present,
      value  => "1",
    }

### manage entry with comment

    sysctl { "net.ipv4.ip_forward":
      ensure  => present,
      value   => "1",
      comment => "test",
    }

### delete entry

    sysctl { "kernel.sysrq":
      ensure => absent,
    }

### remove comment from entry

    sysctl { "kernel.sysrq":
      ensure  => present,
      comment => "",
    }

### manage entry in another sysctl.conf location

    sysctl { "net.ipv4.ip_forward":
      ensure => present,
      value  => "1",
      target => "/etc/sysctl.d/forwarding.conf",
    }
## syslog provider

This is a custom type and provider supplied by `augeasproviders`.

### manage entry

    syslog { "my test":
      ensure      => present,
      facility    => "local2",
      level       => "*",
      action_type => "file",
      action      => "/var/log/test.log",
    }

### manage entry with no file sync

    syslog { "cron.*":
      ensure      => present,
      facility    => "cron",
      level       => "*",
      action_type => "file",
      action      => "/var/log/cron",
      no_sync     => true,
    }

### manage remote hostname entry

    syslog { "my test":
      ensure      => present,
      facility    => "local2",
      level       => "*",
      action_type => "hostname",
      action      => "centralserver",
    }

### manage user destination entry

    syslog { "my test":
      ensure      => present,
      facility    => "local2",
      level       => "*",
      action_type => "user",
      action      => "root",
    }

### manage program entry

    syslog { "my test":
      ensure      => present,
      facility    => "local2",
      level       => "*",
      action_type => "program",
      action      => "/usr/bin/foo",
    }

### delete entry

    syslog { "mail.*":
      ensure      => absent,
      facility    => "mail",
      level       => "*",
      action_type => "file",
      action      => "/var/log/maillog",
    }

### manage entry in another syslog location

    syslog { "my test":
      ensure      => present,
      facility    => "local2",
      level       => "*",
      action_type => "file",
      action      => "/var/log/test.log",
      target      => "/etc/rsyslog.conf",
    }
