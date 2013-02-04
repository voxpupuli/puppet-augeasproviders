#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:apache_setenv).provider(:augeas)


describe provider_class do
  before :each do
    FileTest.stubs(:exist?).returns false
    FileTest.stubs(:exist?).with('/etc/apache2/apache2.conf').returns true
  end

  context "with empty file" do
    let(:tmptarget) { aug_fixture("empty") }
    let(:target) { tmptarget.path }

    it "should create simple new entry" do
      apply!(Puppet::Type.type(:apache_setenv).new(
        :name     => 'TEST',
        :value    => 'test',
        :target   => target,
        :provider => 'augeas'
      ))

      augparse(target, "ApacheSetEnv.lns", '
        {}
      ')
      true
    end
  end

end
