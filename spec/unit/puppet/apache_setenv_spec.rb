#!/usr/bin/env rspec

require 'spec_helper'

FileTest.stubs(:exist?).returns false
FileTest.stubs(:exist?).with('/etc/apache2/apache2.conf').returns true
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
        :ensure   => "present",
        :target   => target,
        :provider => 'augeas'
      ))

      augparse(target, "Httpd.lns", '{ "directive" = "SetEnv" { "arg" = "TEST" } { "arg" = "test" } }')
    end
  end

  context "with full file" do
    let(:tmptarget) { aug_fixture("full") }
    let(:target) { tmptarget.path }

    it "should list instances" do
      provider_class.stubs(:target).returns(target)
      inst = provider_class.instances.map { |p|
        {
          :name => p.get(:name),
          :ensure => p.get(:ensure),
          :value => p.get(:value)
        }
      }

      inst.size.should == 2
      inst[0].should == {:name=>"TEST", :ensure=>:present, :value=>"test"}
      inst[1].should == {:name=>"TEST2", :ensure=>:present, :value=>:absent}
    end
  end

  context "with simple file" do
    let(:tmptarget) { aug_fixture("simple") }
    let(:target) { tmptarget.path }

    it "should create simple new entry" do
      apply!(Puppet::Type.type(:apache_setenv).new(
        :name     => 'FOO',
        :value    => 'test',
        :ensure   => "present",
        :target   => target,
        :provider => 'augeas'
      ))

      # New entry gets added next to existing SetEnv entries
      augparse(target, "Httpd.lns", '
        { "directive" = "SetEnv" { "arg" = "TEST" } }
        { "directive" = "SetEnv" { "arg" = "FQDN" } { "arg" = "ignored" } }
        { "directive" = "SetEnv" { "arg" = "FQDN" } { "arg" = "test.com" } }
        { "directive" = "SetEnv" { "arg" = "FOO" } { "arg" = "test" } }
        { "directive" = "Example" }
      ')
    end

    describe "when update existing" do
      it "should update existing" do
        apply!(Puppet::Type.type(:apache_setenv).new(
          :name     => "FQDN",
          :value    => 'test2.com',
          :ensure   => "present",
          :target   => target,
          :provider => "augeas"
        ))

        # Should have deleted the second FQDN entry
        aug_open(target, "Httpd.lns") do |aug|
          aug.match("directive[.='SetEnv' and arg[1]='FQDN']").size.should == 1
        end

        augparse(target, "Httpd.lns", '
          { "directive" = "SetEnv"
            { "arg" = "TEST" }
          }
          { "directive" = "SetEnv"
            { "arg" = "FQDN" }
            { "arg" = "test2.com" }
          }
          { "directive" = "Example" }
        ')
      end

      it "should clear value when no value" do
        apply!(Puppet::Type.type(:apache_setenv).new(
          :name     => "FQDN",
          :value    => "",
          :ensure   => "present",
          :target   => target,
          :provider => "augeas"
        ))
        augparse(target, "Httpd.lns", '
          { "directive" = "SetEnv" { "arg" = "TEST" } }
          { "directive" = "SetEnv" { "arg" = "FQDN" } }
          { "directive" = "Example" }
        ')
      end
    end

    it "should delete entries" do
      apply!(Puppet::Type.type(:apache_setenv).new(
        :name     => "FQDN",
        :ensure   => "absent",
        :target   => target,
        :provider => "augeas"
      ))

      augparse(target, "Httpd.lns", '
        { "directive" = "SetEnv"
          { "arg" = "TEST" }
        }
        { "directive" = "Example" }
      ')
    end
  end

  context "with broken file" do
    let(:tmptarget) { aug_fixture("broken") }
    let(:target) { tmptarget.path }

    it "should fail to load" do
      txn = apply(Puppet::Type.type(:apache_setenv).new(
        :name     => "FQDN",
        :value    => "test.com",
        :ensure   => "present",
        :target   => target,
        :provider => "augeas"
      ))

      txn.any_failed?.should_not == nil
      @logs.first.level.should == :err
      @logs.first.message.include?(target).should == true
    end
  end
end
