# Changelog

All notable changes to this project will be documented in this file.
Each new release typically also includes the latest modulesync defaults.
These should not affect the functionality of the module.

## [v2.5.0](https://github.com/voxpupuli/puppet-augeasproviders/tree/v2.5.0) (2026-10-22)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/2.4.1...v2.5.0)

**Breaking changes:**

- add Fedora-45, skip Fedora-44, drop Fedora-36, drop Fedora-35 [\#220](https://github.com/voxpupuli/puppet-augeasproviders/pull/220) ([marcusdots](https://github.com/marcusdots))
- drop RedHat-7, CentOs-7, OracleLinux-7 [\#219](https://github.com/voxpupuli/puppet-augeasproviders/pull/219) ([marcusdots](https://github.com/marcusdots))
- drop Ubuntu-20, drop Ubuntu-18 [\#217](https://github.com/voxpupuli/puppet-augeasproviders/pull/217) ([marcusdots](https://github.com/marcusdots))
- drop Debian-12, drop Debian-11 [\#214](https://github.com/voxpupuli/puppet-augeasproviders/pull/214) ([marcusdots](https://github.com/marcusdots))
- Drop puppet, update openvox minimum version to 8.19 [\#199](https://github.com/voxpupuli/puppet-augeasproviders/pull/199) ([TheMeier](https://github.com/TheMeier))
- Migrate dependencies from herculesteam to voxpupuli [\#179](https://github.com/voxpupuli/puppet-augeasproviders/pull/179) ([zilchms](https://github.com/zilchms))
- Drop Puppet 6 support [\#175](https://github.com/voxpupuli/puppet-augeasproviders/pull/175) ([bastelfreak](https://github.com/bastelfreak))
- Resolve puppetserver log warnings caused by undefined global variables [\#171](https://github.com/voxpupuli/puppet-augeasproviders/pull/171) ([walkleyn](https://github.com/walkleyn))

**Implemented enhancements:**

- Add autofs provider and type [\#92](https://github.com/voxpupuli/puppet-augeasproviders/issues/92)
- add RedHat-10, RedHat-9, CentOS-10, RockyLinux-9, RockyLinux-10, AlmaLinux-10, OracleLinux-10, Oraclelinux-9 [\#218](https://github.com/voxpupuli/puppet-augeasproviders/pull/218) ([marcusdots](https://github.com/marcusdots))
- add Ubuntu-26, Ubuntu-24, Ubuntu-22 [\#216](https://github.com/voxpupuli/puppet-augeasproviders/pull/216) ([marcusdots](https://github.com/marcusdots))
- add Debian-13 [\#215](https://github.com/voxpupuli/puppet-augeasproviders/pull/215) ([marcusdots](https://github.com/marcusdots))
- Update requirements to allow OpenVox 9 [\#211](https://github.com/voxpupuli/puppet-augeasproviders/pull/211) ([sebastianrakel](https://github.com/sebastianrakel))
- Add support for Debian 12 [\#200](https://github.com/voxpupuli/puppet-augeasproviders/pull/200) ([smortex](https://github.com/smortex))
- Allow `puppet-augeasproviders_ssh` 7.x [\#197](https://github.com/voxpupuli/puppet-augeasproviders/pull/197) ([TheMeier](https://github.com/TheMeier))
- metadata.json: Add OpenVox [\#195](https://github.com/voxpupuli/puppet-augeasproviders/pull/195) ([jstraw](https://github.com/jstraw))
- puppet/augeasproviders\_sysctl: Allow 3.x [\#194](https://github.com/voxpupuli/puppet-augeasproviders/pull/194) ([zilchms](https://github.com/zilchms))
- puppet/augeasproviders\_ssh: Allow 6.x [\#193](https://github.com/voxpupuli/puppet-augeasproviders/pull/193) ([zilchms](https://github.com/zilchms))
- puppet/augeasproviders\_shellvar: Allow 6.x [\#192](https://github.com/voxpupuli/puppet-augeasproviders/pull/192) ([zilchms](https://github.com/zilchms))
- puppet/augeasproviders\_postgresql: Allow 5.x [\#191](https://github.com/voxpupuli/puppet-augeasproviders/pull/191) ([zilchms](https://github.com/zilchms))
- puppet/augeasproviders\_pam: Allow 4.x [\#190](https://github.com/voxpupuli/puppet-augeasproviders/pull/190) ([zilchms](https://github.com/zilchms))
- puppet/augeasproviders\_mounttab: Allow 4.x [\#189](https://github.com/voxpupuli/puppet-augeasproviders/pull/189) ([zilchms](https://github.com/zilchms))
- puppet/augeasproviders\_grub: Allow 5.x [\#188](https://github.com/voxpupuli/puppet-augeasproviders/pull/188) ([zilchms](https://github.com/zilchms))
- puppet/augeasproviders\_base: Allow 4.x [\#187](https://github.com/voxpupuli/puppet-augeasproviders/pull/187) ([zilchms](https://github.com/zilchms))
- puppet/augeasproviders\_apache: Allow 5.x [\#186](https://github.com/voxpupuli/puppet-augeasproviders/pull/186) ([zilchms](https://github.com/zilchms))
- puppet/augeasproviders\_syslog: Allow 3.x [\#183](https://github.com/voxpupuli/puppet-augeasproviders/pull/183) ([zilchms](https://github.com/zilchms))
- puppet/augeasproviders\_puppet: Allow 3.x [\#182](https://github.com/voxpupuli/puppet-augeasproviders/pull/182) ([zilchms](https://github.com/zilchms))
- puppet/augeasproviders\_nagios: Allow 3.x [\#181](https://github.com/voxpupuli/puppet-augeasproviders/pull/181) ([zilchms](https://github.com/zilchms))
- puppetlabs/stdlib: Allow 9.x [\#176](https://github.com/voxpupuli/puppet-augeasproviders/pull/176) ([bastelfreak](https://github.com/bastelfreak))

**Fixed bugs:**

- pg\_hba should validate that target is an absolute path [\#44](https://github.com/voxpupuli/puppet-augeasproviders/issues/44)

**Closed issues:**

- Missing REFERENCE.md [\#203](https://github.com/voxpupuli/puppet-augeasproviders/issues/203)
- Puppet7 support [\#172](https://github.com/voxpupuli/puppet-augeasproviders/issues/172)
- Sysctl lense fails for keys that contain colons \(":"\) [\#166](https://github.com/voxpupuli/puppet-augeasproviders/issues/166)
- puppet 4 ?  [\#144](https://github.com/voxpupuli/puppet-augeasproviders/issues/144)

**Merged pull requests:**

- Generate REFERENCE.md and add some missing param tags [\#204](https://github.com/voxpupuli/puppet-augeasproviders/pull/204) ([bwitt](https://github.com/bwitt))
- Migrate module to Vox Pupuli [\#184](https://github.com/voxpupuli/puppet-augeasproviders/pull/184) ([zilchms](https://github.com/zilchms))
- Fix incorrect Apache-2 license [\#174](https://github.com/voxpupuli/puppet-augeasproviders/pull/174) ([bastelfreak](https://github.com/bastelfreak))
- Dependency and Support Bump [\#173](https://github.com/voxpupuli/puppet-augeasproviders/pull/173) ([trevor-vaughan](https://github.com/trevor-vaughan))
- Remove Gemfile.lock [\#170](https://github.com/voxpupuli/puppet-augeasproviders/pull/170) ([smortex](https://github.com/smortex))
- Travis-CI: Drop Ruby 1.8.7/1.9.3 tests [\#165](https://github.com/voxpupuli/puppet-augeasproviders/pull/165) ([bastelfreak](https://github.com/bastelfreak))
- Bump rake from 10.3.2 to 12.3.3 [\#161](https://github.com/voxpupuli/puppet-augeasproviders/pull/161) ([dependabot[bot]](https://github.com/apps/dependabot))
- Fix broken headings in Markdown files [\#148](https://github.com/voxpupuli/puppet-augeasproviders/pull/148) ([bryant1410](https://github.com/bryant1410))

## [2.4.1](https://github.com/voxpupuli/puppet-augeasproviders/tree/2.4.1) (2019-06-26)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/2.4.0...2.4.1)

## [2.4.0](https://github.com/voxpupuli/puppet-augeasproviders/tree/2.4.0) (2019-04-30)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/2.2.1...2.4.0)

**Closed issues:**

- Incorrect dependency for augeasproviders\_grub [\#156](https://github.com/voxpupuli/puppet-augeasproviders/issues/156)

## [2.2.1](https://github.com/voxpupuli/puppet-augeasproviders/tree/2.2.1) (2019-03-01)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/2.2.0...2.2.1)

## [2.2.0](https://github.com/voxpupuli/puppet-augeasproviders/tree/2.2.0) (2019-03-01)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v2.1.3...2.2.0)

**Implemented enhancements:**

- Augeas-based provider for yumrepo [\#134](https://github.com/voxpupuli/puppet-augeasproviders/issues/134)
- Split/segregate core library from collection of providers [\#59](https://github.com/voxpupuli/puppet-augeasproviders/issues/59)

**Closed issues:**

- Not possible to add multiple kernel parameters with the same name. [\#138](https://github.com/voxpupuli/puppet-augeasproviders/issues/138)
- Clarify herculesteam-augeasproviders vs domcleal-augeasproviders ? [\#137](https://github.com/voxpupuli/puppet-augeasproviders/issues/137)

## [v2.1.3](https://github.com/voxpupuli/puppet-augeasproviders/tree/v2.1.3) (2014-12-11)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v2.1.2...v2.1.3)

## [v2.1.2](https://github.com/voxpupuli/puppet-augeasproviders/tree/v2.1.2) (2014-12-11)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v2.1.1...v2.1.2)

**Implemented enhancements:**

- pam: support composite namevars [\#115](https://github.com/voxpupuli/puppet-augeasproviders/issues/115)
- Please generate diffs when running on verbose mode [\#99](https://github.com/voxpupuli/puppet-augeasproviders/issues/99)

**Fixed bugs:**

- sshd\_config needs to consider KexAlgorithms, Ciphers and AcceptEnv to be arrays [\#128](https://github.com/voxpupuli/puppet-augeasproviders/issues/128)
- sysctl provider fails if multiple instances of value are declared in sysctl.conf [\#123](https://github.com/voxpupuli/puppet-augeasproviders/issues/123)
- Shellvar comment parameter make a mess of existing comments [\#119](https://github.com/voxpupuli/puppet-augeasproviders/issues/119)
- shellvar: quoted does not converge [\#109](https://github.com/voxpupuli/puppet-augeasproviders/issues/109)
- shellvar: export + comment requires two passes [\#108](https://github.com/voxpupuli/puppet-augeasproviders/issues/108)

**Closed issues:**

- pam module not enforcing the after [\#135](https://github.com/voxpupuli/puppet-augeasproviders/issues/135)
- Conflicts with  fiddyspence/sysctl [\#129](https://github.com/voxpupuli/puppet-augeasproviders/issues/129)
- ShellVar array\_append does not work to add values from different places [\#126](https://github.com/voxpupuli/puppet-augeasproviders/issues/126)
- host provider doesn't add aliases when similar lines exist in /etc/hosts [\#122](https://github.com/voxpupuli/puppet-augeasproviders/issues/122)
- shellvar: array + quoted not working [\#110](https://github.com/voxpupuli/puppet-augeasproviders/issues/110)

## [v2.1.1](https://github.com/voxpupuli/puppet-augeasproviders/tree/v2.1.1) (2014-11-17)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v2.0.0...v2.1.1)

## [v2.0.0](https://github.com/voxpupuli/puppet-augeasproviders/tree/v2.0.0) (2014-08-13)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v1.2.0...v2.0.0)

**Fixed bugs:**

- pam: Could not set 'present' on ensure: undefined method `each' for nil:NilClass if arguments is not define [\#100](https://github.com/voxpupuli/puppet-augeasproviders/pull/100) ([Feandil](https://github.com/Feandil))

**Closed issues:**

- Symbolic link !! [\#130](https://github.com/voxpupuli/puppet-augeasproviders/issues/130)

**Merged pull requests:**

- Retry Travis build steps [\#117](https://github.com/voxpupuli/puppet-augeasproviders/pull/117) ([domcleal](https://github.com/domcleal))
- Fix use of seq entries with Puppet 3.4 optimisation \(GH issue \#101\) [\#107](https://github.com/voxpupuli/puppet-augeasproviders/pull/107) ([raphink](https://github.com/raphink))

## [v1.2.0](https://github.com/voxpupuli/puppet-augeasproviders/tree/v1.2.0) (2014-06-10)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v1.1.0...v1.2.0)

**Implemented enhancements:**

- Feature: The providers should only open the target file once per given run. [\#67](https://github.com/voxpupuli/puppet-augeasproviders/issues/67)

**Fixed bugs:**

- Adding two host entries; Entries are getting combined into one line on the first run, then properly inserted in the second run [\#101](https://github.com/voxpupuli/puppet-augeasproviders/issues/101)
- sshd\_config keys should be case insensitive [\#15](https://github.com/voxpupuli/puppet-augeasproviders/issues/15)

**Closed issues:**

- require statements demand exact path unnecessarily [\#82](https://github.com/voxpupuli/puppet-augeasproviders/issues/82)

## [v1.1.0](https://github.com/voxpupuli/puppet-augeasproviders/tree/v1.1.0) (2014-05-05)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v1.0.2...v1.1.0)

**Implemented enhancements:**

- Parameterize augeasproviders class [\#78](https://github.com/voxpupuli/puppet-augeasproviders/issues/78)
- shellvars: support unset and export [\#65](https://github.com/voxpupuli/puppet-augeasproviders/issues/65)
- Improve errors [\#87](https://github.com/voxpupuli/puppet-augeasproviders/pull/87) ([raphink](https://github.com/raphink))
- Use one Augeas handler [\#80](https://github.com/voxpupuli/puppet-augeasproviders/pull/80) ([raphink](https://github.com/raphink))

**Fixed bugs:**

- New shellvars lens breaks unset statements in shellvar provider [\#83](https://github.com/voxpupuli/puppet-augeasproviders/pull/83) ([raphink](https://github.com/raphink))

**Closed issues:**

- Error loading /etc/apache2/envvars with Shellvars lense [\#98](https://github.com/voxpupuli/puppet-augeasproviders/issues/98)
- Tests fail with Puppet 3.5.1 [\#96](https://github.com/voxpupuli/puppet-augeasproviders/issues/96)
- Reorganize specs properly, separating types and providers [\#77](https://github.com/voxpupuli/puppet-augeasproviders/issues/77)
- Unit tests break with Puppet 3.4.X [\#72](https://github.com/voxpupuli/puppet-augeasproviders/issues/72)
- Bug: When managing both Port and ListenAddress in sshd\_config, Port \*must\* precede ListenAddress [\#68](https://github.com/voxpupuli/puppet-augeasproviders/issues/68)
- setting kernel parameters in format key=value [\#61](https://github.com/voxpupuli/puppet-augeasproviders/issues/61)
- Charset problems in docs, specs or metadata files [\#58](https://github.com/voxpupuli/puppet-augeasproviders/issues/58)
- Provider\(s\) for Httpd.lns [\#48](https://github.com/voxpupuli/puppet-augeasproviders/issues/48)

**Merged pull requests:**

- Add parsed\_as? method [\#93](https://github.com/voxpupuli/puppet-augeasproviders/pull/93) ([raphink](https://github.com/raphink))
- Add rm\_node to accessors to remove subnode instead of clearing them [\#73](https://github.com/voxpupuli/puppet-augeasproviders/pull/73) ([raphink](https://github.com/raphink))
- Add an apache\_directive type and provider [\#63](https://github.com/voxpupuli/puppet-augeasproviders/pull/63) ([raphink](https://github.com/raphink))
- Add :array\_append parameter to shellvar type/provider [\#62](https://github.com/voxpupuli/puppet-augeasproviders/pull/62) ([raphink](https://github.com/raphink))

## [v1.0.2](https://github.com/voxpupuli/puppet-augeasproviders/tree/v1.0.2) (2013-10-28)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v1.0.1...v1.0.2)

**Closed issues:**

- sysctl gives returned error 255 first time [\#53](https://github.com/voxpupuli/puppet-augeasproviders/issues/53)

## [v1.0.1](https://github.com/voxpupuli/puppet-augeasproviders/tree/v1.0.1) (2013-10-05)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v1.0.0...v1.0.1)

**Closed issues:**

- sysctl applies when apply =\> false [\#56](https://github.com/voxpupuli/puppet-augeasproviders/issues/56)
- Spaces in value [\#50](https://github.com/voxpupuli/puppet-augeasproviders/issues/50)

## [v1.0.0](https://github.com/voxpupuli/puppet-augeasproviders/tree/v1.0.0) (2013-08-23)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v0.7.0...v1.0.0)

**Closed issues:**

- Sysctl type fails on some systems when run from a backgrounded puppet agent [\#47](https://github.com/voxpupuli/puppet-augeasproviders/issues/47)
- Array of addresses support in pg\_hba type [\#45](https://github.com/voxpupuli/puppet-augeasproviders/issues/45)

## [v0.7.0](https://github.com/voxpupuli/puppet-augeasproviders/tree/v0.7.0) (2013-06-03)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v0.6.1...v0.7.0)

**Closed issues:**

- mailalias fails when called by maillist [\#41](https://github.com/voxpupuli/puppet-augeasproviders/issues/41)

**Merged pull requests:**

- shellvar: add support for array values [\#43](https://github.com/voxpupuli/puppet-augeasproviders/pull/43) ([raphink](https://github.com/raphink))
- mailalias: add smart quoting for recipients \(Fix issue \#41\) [\#42](https://github.com/voxpupuli/puppet-augeasproviders/pull/42) ([raphink](https://github.com/raphink))
- Add an alias parameter to sysctl [\#40](https://github.com/voxpupuli/puppet-augeasproviders/pull/40) ([mfournier](https://github.com/mfournier))
- Sysctl: Add 'apply' and use a command to apply values [\#29](https://github.com/voxpupuli/puppet-augeasproviders/pull/29) ([raphink](https://github.com/raphink))

## [v0.6.1](https://github.com/voxpupuli/puppet-augeasproviders/tree/v0.6.1) (2013-04-20)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v0.6.0...v0.6.1)

**Implemented enhancements:**

- Error adding rule to rsyslog.conf [\#31](https://github.com/voxpupuli/puppet-augeasproviders/issues/31)

**Fixed bugs:**

- Error while applying manifest [\#34](https://github.com/voxpupuli/puppet-augeasproviders/issues/34)

**Closed issues:**

- sysctl does not create file if used with target =\>  [\#36](https://github.com/voxpupuli/puppet-augeasproviders/issues/36)

## [v0.6.0](https://github.com/voxpupuli/puppet-augeasproviders/tree/v0.6.0) (2013-04-01)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v0.5.3...v0.6.0)

**Closed issues:**

- unable to upgrade or uninstall module [\#28](https://github.com/voxpupuli/puppet-augeasproviders/issues/28)

## [v0.5.3](https://github.com/voxpupuli/puppet-augeasproviders/tree/v0.5.3) (2013-03-20)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v0.5.2...v0.5.3)

**Merged pull requests:**

- Fix sshd\_config namevar [\#26](https://github.com/voxpupuli/puppet-augeasproviders/pull/26) ([raphink](https://github.com/raphink))

## [v0.5.2](https://github.com/voxpupuli/puppet-augeasproviders/tree/v0.5.2) (2013-02-23)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v0.5.1...v0.5.2)

**Fixed bugs:**

- "No such file or directory" with docs symlinks [\#25](https://github.com/voxpupuli/puppet-augeasproviders/issues/25)

**Closed issues:**

- Warnings after installing [\#20](https://github.com/voxpupuli/puppet-augeasproviders/issues/20)

**Merged pull requests:**

- sshd\_config: Simplify type and provider with key as namevar [\#24](https://github.com/voxpupuli/puppet-augeasproviders/pull/24) ([raphink](https://github.com/raphink))
- Add prefetch [\#22](https://github.com/voxpupuli/puppet-augeasproviders/pull/22) ([raphink](https://github.com/raphink))

## [v0.5.1](https://github.com/voxpupuli/puppet-augeasproviders/tree/v0.5.1) (2012-12-04)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v0.5.0...v0.5.1)

## [v0.5.0](https://github.com/voxpupuli/puppet-augeasproviders/tree/v0.5.0) (2012-12-01)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v0.4.0...v0.5.0)

**Merged pull requests:**

- Remove wrong indentation in sshd\_config type [\#18](https://github.com/voxpupuli/puppet-augeasproviders/pull/18) ([raphink](https://github.com/raphink))

## [v0.4.0](https://github.com/voxpupuli/puppet-augeasproviders/tree/v0.4.0) (2012-11-08)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v0.3.1...v0.4.0)

**Merged pull requests:**

- Add new type and provider nrpe\_command [\#17](https://github.com/voxpupuli/puppet-augeasproviders/pull/17) ([ckaenzig](https://github.com/ckaenzig))
- Add a syslog provider [\#14](https://github.com/voxpupuli/puppet-augeasproviders/pull/14) ([raphink](https://github.com/raphink))

## [v0.3.1](https://github.com/voxpupuli/puppet-augeasproviders/tree/v0.3.1) (2012-09-25)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v0.3.0...v0.3.1)

**Implemented enhancements:**

- No /augeas//error data logged on Augeas::Error [\#12](https://github.com/voxpupuli/puppet-augeasproviders/issues/12)
- mounttab: Solaris/vfstab support [\#11](https://github.com/voxpupuli/puppet-augeasproviders/issues/11)

**Closed issues:**

- sshd\_config: ability to define more than one ListenAddress [\#13](https://github.com/voxpupuli/puppet-augeasproviders/issues/13)
- mounttab: spec should test that fstab options is optional [\#10](https://github.com/voxpupuli/puppet-augeasproviders/issues/10)

## [v0.3.0](https://github.com/voxpupuli/puppet-augeasproviders/tree/v0.3.0) (2012-09-09)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v0.2.0...v0.3.0)

## [v0.2.0](https://github.com/voxpupuli/puppet-augeasproviders/tree/v0.2.0) (2012-08-26)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v0.1.1...v0.2.0)

## [v0.1.1](https://github.com/voxpupuli/puppet-augeasproviders/tree/v0.1.1) (2012-07-21)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v0.1.0...v0.1.1)

**Merged pull requests:**

- Setup for Travis CI [\#8](https://github.com/voxpupuli/puppet-augeasproviders/pull/8) ([raphink](https://github.com/raphink))
- Add sshd\_config\_subsystem type and provider [\#5](https://github.com/voxpupuli/puppet-augeasproviders/pull/5) ([raphink](https://github.com/raphink))
- Add MACs to array type of entries [\#4](https://github.com/voxpupuli/puppet-augeasproviders/pull/4) ([raphink](https://github.com/raphink))
- Add support for arrays for \(\(Allow|Deny\)\(Groups|Users\)\)|AcceptEnv entries [\#3](https://github.com/voxpupuli/puppet-augeasproviders/pull/3) ([raphink](https://github.com/raphink))
- Add Match groups to self.instances [\#2](https://github.com/voxpupuli/puppet-augeasproviders/pull/2) ([raphink](https://github.com/raphink))

## [v0.1.0](https://github.com/voxpupuli/puppet-augeasproviders/tree/v0.1.0) (2012-07-14)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v0.0.4...v0.1.0)

## [v0.0.4](https://github.com/voxpupuli/puppet-augeasproviders/tree/v0.0.4) (2012-07-01)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v0.0.3...v0.0.4)

## [v0.0.3](https://github.com/voxpupuli/puppet-augeasproviders/tree/v0.0.3) (2012-03-05)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v0.0.2...v0.0.3)

## [v0.0.2](https://github.com/voxpupuli/puppet-augeasproviders/tree/v0.0.2) (2012-03-04)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/v0.0.1...v0.0.2)

## [v0.0.1](https://github.com/voxpupuli/puppet-augeasproviders/tree/v0.0.1) (2012-03-04)

[Full Changelog](https://github.com/voxpupuli/puppet-augeasproviders/compare/47f709716273b137d21e915fae8a444c8a7cef38...v0.0.1)



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
