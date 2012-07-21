# Changelog

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
