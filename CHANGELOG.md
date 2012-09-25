# Changelog

## 0.3.1
* all: fix missing require causing load errors
* sshd_config: store multiple values for a setting as multiple entries, e.g.
  multiple ListenAddress lines (issue #13)
* docs: minor fixes
* devel: test Puppet 3.0

## 0.3.0
* sysctl: new type for managing sysctl.conf entries
* mounttab: add Solaris /etc/vfstab support
* mounttab: fix options property idempotency
* mounttab: fix key=value options in fstab instances
* host: fix comment and host_aliases properties idempotency
* all: log /augeas//error output when unable to save
* packaging: hard mount_providers dependency removed
* devel: augparse used to test providers against expected tree
* devel: augeas submodule included for testing against latest lenses

## 0.2.0
* mounttab: new provider for mounttab type in puppetlabs-mount_providers
  (supports fstab only, no vfstab), mount_providers now a dependency
* devel: librarian-puppet used to install Puppet module dependencies

## 0.1.1
* host: fix host_aliases param support pre-2.7
* sshd_config: find Match groups in instances/ralsh
* sshd_config: support arrays for ((Allow|Deny)(Groups|Users))|AcceptEnv|MACs
* sshd_config_subsystem: new type and provider (Raphaël Pinson)
* devel: use Travis CI, specify deps via Gemfile + bundler
* specs: fixes for 0.25 and 2.6 series

## 0.1.0
* host: fix pre-2.7 compatibility when without comment property
* sshd_config: new type and provider (Raphaël Pinson)
* all: fix provider confine to enable use in same run as ruby-augeas install
  (Puppet #14822)
* devel: refactor common augopen code into utility class
* specs: fix both Ruby 1.8 and mocha 0.12 compatibility

## 0.0.4
* host: fix handling of multiple host_aliases
* host: fix handling of empty comment string, now removes comment
* host: fix missing ensure and comment parameters in puppet resource, only
  return aliases if present
* mailalias: fix missing ensure parameter in puppet resource
* specs: added comprehensive test harness for both providers

## 0.0.3
* all: add instances methods to enable `puppet resource`

## 0.0.2
* mailalias: new provider added for builtin mailalias type

## 0.0.1
* host: new provider added for builtin host type
