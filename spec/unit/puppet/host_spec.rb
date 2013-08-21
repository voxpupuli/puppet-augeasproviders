#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:host).provider(:augeas)

describe provider_class do
  before :all do
    # Pre-2.7.0, there was no comment property on the host type so this will
    # produce errors while testing against old versions, so add it.
    # Don't call validattr? or this keeps a negative cache of the property
    unless Puppet::Type.type(:host).validproperty? :comment
      Puppet::Type.type(:host).newproperty(:comment) do
        desc "Monkey patched"
      end
    end
  end

  before :each do
    FileTest.stubs(:exist?).returns false
    FileTest.stubs(:exist?).with('/etc/hosts').returns true
  end

  context "with empty file" do
    let(:tmptarget) { aug_fixture("empty") }
    let(:target) { tmptarget.path }

    it "should create simple new entry" do
      apply!(Puppet::Type.type(:host).new(
        :name     => "foo",
        :ip       => "192.168.1.1",
        :target   => target,
        :provider => "augeas"
      ))

      augparse(target, "Hosts.lns", '
        { "1"
          { "ipaddr" = "192.168.1.1" }
          { "canonical" = "foo" }
        }
      ')
    end

    it "should create new entry" do
      apply!(Puppet::Type.type(:host).new(
        :name     => "foo",
        :ip       => "192.168.1.1",
        :host_aliases => [ "foo-a", "foo-b" ],
        :comment  => "test",
        :target   => target,
        :provider => "augeas"
      ))

      augparse(target, "Hosts.lns", '
        { "1"
          { "ipaddr" = "192.168.1.1" }
          { "canonical" = "foo" }
          { "alias" = "foo-a" }
          { "alias" = "foo-b" }
          { "#comment" = "test" }
        }
      ')
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
          :ip => p.get(:ip),
          :host_aliases => p.get(:host_aliases),
          :comment => p.get(:comment),
        }
      }

      inst.size.should == 4
      inst[0].should == {:name=>"localhost.localdomain", :ensure=>:present, :ip=>"127.0.0.1", :host_aliases=>["localhost"], :comment=>:absent}
      inst[1].should == {:name=>"localhost6.localdomain6", :ensure=>:present, :ip=>"::1", :host_aliases=>["localhost6"], :comment=>:absent}
      inst[2].should == {:name=>"iridium", :ensure=>:present, :ip=>"192.168.0.5", :host_aliases=>["iridium.example.com"], :comment=>:absent}
      inst[3].should == {:name=>"argon", :ensure=>:present, :ip=>"192.168.0.10", :host_aliases=>:absent, :comment=>"NAS"}
    end

    it "should delete entries" do
      apply!(Puppet::Type.type(:host).new(
        :name     => "iridium",
        :ensure   => "absent",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Hosts.lns") do |aug|
        aug.match("*[canonical = 'iridium']").should == []
      end
    end

    it "should update IP address" do
      apply!(Puppet::Type.type(:host).new(
        :name     => "iridium",
        :ip       => "1.2.3.4",
        :target   => target,
        :provider => "augeas"
      ))

      augparse_filter(target, "Hosts.lns", "*[canonical='iridium']", '
        { "1"
          { "ipaddr" = "1.2.3.4" }
          { "canonical" = "iridium" }
          { "alias" = "iridium.example.com" }
        }
      ')
    end

    describe "when updating host_aliases" do
      it "should add an alias" do
        apply!(Puppet::Type.type(:host).new(
          :name     => "argon",
          :host_aliases => [ "test-a" ],
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Hosts.lns", "*[canonical='argon']", '
          { "1"
            { "ipaddr" = "192.168.0.10" }
            { "canonical" = "argon" }
            { "alias" = "test-a" }
            { "#comment" = "NAS" }
          }
        ')
      end

      it "should replace an alias" do
        apply!(Puppet::Type.type(:host).new(
          :name     => "iridium",
          :host_aliases => [ "test-a" ],
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Hosts.lns", "*[canonical='iridium']", '
          { "1"
            { "ipaddr" = "192.168.0.5" }
            { "canonical" = "iridium" }
            { "alias" = "test-a" }
          }
        ')
      end

      it "should add multiple aliases" do
        apply!(Puppet::Type.type(:host).new(
          :name     => "iridium",
          :host_aliases => [ "test-a", "test-b" ],
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Hosts.lns", "*[canonical='iridium']", '
          { "1"
            { "ipaddr" = "192.168.0.5" }
            { "canonical" = "iridium" }
            { "alias" = "test-a" }
            { "alias" = "test-b" }
          }
        ')
      end

      it "should remove aliases" do
        apply!(Puppet::Type.type(:host).new(
          :name     => "iridium",
          :host_aliases => [ ],
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Hosts.lns", "*[canonical='iridium']", '
          { "1"
            { "ipaddr" = "192.168.0.5" }
            { "canonical" = "iridium" }
          }
        ')
      end
    end

    describe "when updating comment" do
      it "should add comment" do
        apply!(Puppet::Type.type(:host).new(
          :name     => "iridium",
          :comment  => "test comment",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Hosts.lns", "*[canonical='iridium']", '
          { "1"
            { "ipaddr" = "192.168.0.5" }
            { "canonical" = "iridium" }
            { "alias" = "iridium.example.com" }
            { "#comment" = "test comment" }
          }
        ')
      end

      it "should remove comment" do
        apply!(Puppet::Type.type(:host).new(
          :name     => "argon",
          :comment  => "",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Hosts.lns", "*[canonical='argon']", '
          { "1"
            { "ipaddr" = "192.168.0.10" }
            { "canonical" = "argon" }
          }
        ')
      end
    end
  end

  context "with broken file" do
    let(:tmptarget) { aug_fixture("broken") }
    let(:target) { tmptarget.path }

    it "should fail to load" do
      txn = apply(Puppet::Type.type(:host).new(
        :name     => "foo",
        :ip       => "192.168.1.1",
        :target   => target,
        :provider => "augeas"
      ))

      txn.any_failed?.should_not == nil
      @logs.first.level.should == :err
      @logs.first.message.include?(target).should == true
    end
  end

  context "without comment property on <2.7" do
    let(:tmptarget) { aug_fixture("full") }
    let(:target) { tmptarget.path }

    before :each do
      # Change Puppet::Type::Host.validattr? to return false instead for
      # comment so it throws the same errors as Puppet < 2.7
      validattr = Puppet::Type.type(:host).method(:validattr?)
      Puppet::Type.type(:host).stubs(:validattr?).with { |arg| validattr.call(arg) }.returns(true)
      Puppet::Type.type(:host).stubs(:validattr?).with { |arg| ! validattr.call(arg) }.returns(false)
      Puppet::Type.type(:host).stubs(:validattr?).with(:comment).returns(false)
    end

    it "should create simple new entry" do
      apply!(Puppet::Type.type(:host).new(
        :name     => "foo",
        :ip       => "192.168.1.1",
        :target   => target,
        :provider => "augeas"
      ))

      augparse_filter(target, "Hosts.lns", "*[canonical='foo']", '
         { "1"
           { "ipaddr" = "192.168.1.1" }
           { "canonical" = "foo" }
         }
      ')
    end
  end
end
