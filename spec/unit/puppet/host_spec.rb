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

      aug_open(target, "Hosts.lns") do |aug|
        aug.get("./1/ipaddr").should == "192.168.1.1"
        aug.get("./1/canonical").should == "foo"
        aug.match("./1/alias").should == []
        aug.match("./1/#comment").should == []
      end
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

      aug_open(target, "Hosts.lns") do |aug|
        aug.get("./1/ipaddr").should == "192.168.1.1"
        aug.get("./1/canonical").should == "foo"
        aug.match("./1/alias").size.should == 2
        aug.get("./1/alias[1]").should == "foo-a"
        aug.get("./1/alias[2]").should == "foo-b"
        aug.get("./1/#comment").should == "test"
      end
    end
  end

  context "with full file" do
    let(:tmptarget) { aug_fixture("full") }
    let(:target) { tmptarget.path }

    it "should list instances" do
      provider_class.stubs(:file).returns(target)
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

      aug_open(target, "Hosts.lns") do |aug|
        aug.get("./3/canonical").should == "iridium"
        aug.get("./3/ipaddr").should == "1.2.3.4"
      end
    end

    describe "when updating host_aliases" do
      it "should add an alias" do
        apply!(Puppet::Type.type(:host).new(
          :name     => "argon",
          :host_aliases => [ "test-a" ],
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Hosts.lns") do |aug|
          aug.get("./4/canonical").should == "argon"
          aug.match("./4/alias").size.should == 1
          aug.get("./4/alias").should == "test-a"
        end
      end

      it "should replace an alias" do
        apply!(Puppet::Type.type(:host).new(
          :name     => "iridium",
          :host_aliases => [ "test-a" ],
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Hosts.lns") do |aug|
          aug.get("./3/canonical").should == "iridium"
          aug.match("./3/alias").size.should == 1
          aug.get("./3/alias").should == "test-a"
        end
      end

      it "should add multiple aliases" do
        apply!(Puppet::Type.type(:host).new(
          :name     => "iridium",
          :host_aliases => [ "test-a", "test-b" ],
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Hosts.lns") do |aug|
          aug.get("./3/canonical").should == "iridium"
          aug.match("./3/alias").size.should == 2
          aug.get("./3/alias[1]").should == "test-a"
          aug.get("./3/alias[2]").should == "test-b"
        end
      end

      it "should remove aliases" do
        apply!(Puppet::Type.type(:host).new(
          :name     => "iridium",
          :host_aliases => [ ],
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Hosts.lns") do |aug|
          aug.get("./3/canonical").should == "iridium"
          aug.match("./3/alias").should == []
        end
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

        aug_open(target, "Hosts.lns") do |aug|
          aug.get("./3/canonical").should == "iridium"
          aug.get("./3/#comment").should == "test comment"
        end
      end

      it "should remove comment" do
        apply!(Puppet::Type.type(:host).new(
          :name     => "argon",
          :comment  => "",
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Hosts.lns") do |aug|
          aug.get("./4/canonical").should == "argon"
          aug.match("./4/#comment").should == []
        end
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

      aug_open(target, "Hosts.lns") do |aug|
        aug.get("./5/ipaddr").should == "192.168.1.1"
        aug.get("./5/canonical").should == "foo"
        aug.match("./5/alias").should == []
        aug.match("./5/#comment").should == []
      end
    end
  end
end
