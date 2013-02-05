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

      augparse(target, "Httpd.lns", '{ "directive" = "SetEnv" { "arg" = "TEST" } { "arg" = "test" } }')
    end
  end

  context "with simple file" do
    let(:tmptarget) { aug_fixture("simple") }
    let(:target) { tmptarget.path }

    describe "when update existing" do
      it "should update existing" do
        apply!(Puppet::Type.type(:apache_setenv).new(
          :name     => "FQDN",
          :value    => 'test2.com',
          :comment  => "test comment",
          :target   => target,
          :provider => "augeas"
        ))
        augparse(target, "Httpd.lns", '
          { "directive" = "SetEnv"
            { "arg" = "TEST" }
          }
          { "directive" = "SetEnv"
            { "arg" = "FQDN" }
            { "arg" = "test2.com" }
          }
        ')
      end

      it "should clear value when no value" do
        apply!(Puppet::Type.type(:apache_setenv).new(
          :name     => "FQDN",
          :value    => "",
          :comment  => "test comment",
          :target   => target,
          :provider => "augeas"
        ))
        augparse(target, "Httpd.lns", '
          { "directive" = "SetEnv" { "arg" = "TEST" } } 
          { "directive" = "SetEnv" { "arg" = "FQDN" } }
        ')
      end
    end
  end
end
