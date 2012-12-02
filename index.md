---
layout: minimal
title: augeasproviders
---

## Alternative Augeas-based providers for Puppet

This module provides alternative providers for core Puppet types such as
`host` and `mailalias` using the Augeas configuration library.  It also adds
some of its own types for new functionality.

The advantage of using Augeas over the default Puppet `parsedfile`
implementations is that Augeas will go to great lengths to preserve file
formatting and comments, while also failing safely when needed.

These providers will hide *all* of the Augeas commands etc., you don't need to
know anything about Augeas to make use of it.

    # Updates kernel parameter in GRUB or GRUB 2 config
    kernel_parameter { "elevator":
      value => "deadline",
    }

If you want to make changes to config files in your own way, you should use
the `augeas` type directly.  For more information about Augeas, see the
[web site](http://augeas.net) or the
[Puppet/Augeas](http://projects.puppetlabs.com/projects/puppet/wiki/Puppet_Augeas)
wiki page.

## Issues

Please file any issues or suggestions [on GitHub](https://github.com/hercules-team/augeasproviders/issues).
