# Contributing to augeasproviders

## Writing tests

Tests for a `typename` provider live at `spec/unit/puppet/typename_spec.rb` and
their corresponding fixture (starting file) under
`spec/fixture/unit/puppet/typename/`.

Use an rspec context section per fixture and have multiple examples within the
section using it.

Tests use real resources which are applied to the system via the
`AugeasSpec::Fixtures::apply` method to a temporary file created from the
original fixture.  Once applied, the temporary file is loaded back into Augeas
and the contents/structure of the file can be tested.

Execute `rake spec` in the root directory to run them.

## Thoughts about testing methods

After applying the resource, there are a few ways we could test the results of
the file.

* use augparse?  No API today, could generate module file and shell out.
* use Config::Augeas::Validator?  Need to write separate rules, no rootdir
  support and is Perl, not Ruby.
* use XML comparison?  No ruby-augeas support for aug_to_xml.
* use ruby-augeas?  Using this as we can test for specific nodes, values etc
  and compare with rspec.
* use File.read + rspec?  Comparing the whole file will be a problem if Augeas
  lenses change whitespace.

## Requirements

Besides runtime pre-requisites (see README), you need:

* [puppetlabs_spec_helper](https://github.com/puppetlabs/puppetlabs_spec_helper) gem installed
* rspec2
* mocha

## Patches

Please send pull requests via Github, or patches via git send-email to the
author.
