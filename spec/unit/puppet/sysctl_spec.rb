#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:sysctl).provider(:augeas)

describe provider_class do
  before :each do
    FileTest.stubs(:exist?).returns false
    FileTest.stubs(:exist?).with('/etc/sysctl.conf').returns true
  end

  context "with empty file" do
    let(:tmptarget) { aug_fixture("empty") }
    let(:target) { tmptarget.path }

    it "should create simple new entry" do
      apply!(Puppet::Type.type(:sysctl).new(
        :name     => "net.ipv4.ip_forward",
        :value    => "1",
        :target   => target,
        :provider => "augeas"
      ))

      augparse(target, "Sysctl.lns", '
        { "net.ipv4.ip_forward" = "1" }
      ')
    end

    it "should create new entry with comment" do
      apply!(Puppet::Type.type(:sysctl).new(
        :name     => "net.ipv4.ip_forward",
        :value    => "1",
        :comment  => "test",
        :target   => target,
        :provider => "augeas"
      ))

      augparse(target, "Sysctl.lns", '
        { "#comment" = "net.ipv4.ip_forward: test" }
        { "net.ipv4.ip_forward" = "1" }
      ')
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
          :value => p.get(:value),
          :comment => p.get(:comment),
        }
      }

      inst.size.should == 7
      inst[0].should == {:name=>"net.ipv4.ip_forward", :ensure=>:present, :value=>"0", :comment=>:absent}
      inst[1].should == {:name=>"net.ipv4.conf.default.rp_filter", :ensure=>:present, :value=>"1", :comment=>:absent}
      inst[2].should == {:name=>"net.ipv4.conf.default.accept_source_route", :ensure=>:present, :value=>"0", :comment=>"Do not accept source routing"}
      inst[3].should == {:name=>"kernel.sysrq", :ensure=>:present, :value=>"0", :comment=>"controls the System Request debugging functionality of the kernel"}
    end

    it "should create new entry next to commented out entry" do
      apply!(Puppet::Type.type(:sysctl).new(
        :name     => "net.bridge.bridge-nf-call-iptables",
        :value    => "1",
        :target   => target,
        :provider => "augeas"
      ))

      augparse_filter(target, "Sysctl.lns", '*[preceding-sibling::#comment[.="Disable netfilter on bridges."]]', '
        { "net.bridge.bridge-nf-call-ip6tables" = "0" }
        { "#comment" = "net.bridge.bridge-nf-call-iptables = 0" }
        { "net.bridge.bridge-nf-call-iptables" = "1" }
        { "net.bridge.bridge-nf-call-arptables" = "0" }
      ')
    end

    it "should delete entries" do
      apply!(Puppet::Type.type(:sysctl).new(
        :name     => "kernel.sysrq",
        :ensure   => "absent",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Sysctl.lns") do |aug|
        aug.match("kernel.sysrq").should == []
        aug.match("#comment[. =~ regexp('kernel.sysrq:.*')]").should == []
      end
    end

    it "should update value" do
      apply!(Puppet::Type.type(:sysctl).new(
        :name     => "net.ipv4.ip_forward",
        :value    => "1",
        :target   => target,
        :provider => "augeas"
      ))

      augparse_filter(target, "Sysctl.lns", "net.ipv4.ip_forward", '
        { "net.ipv4.ip_forward" = "1" }
      ')
    end

    describe "when updating comment" do
      it "should change comment" do
        apply!(Puppet::Type.type(:sysctl).new(
          :name     => "kernel.sysrq",
          :comment  => "enables the SysRq feature",
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Sysctl.lns") do |aug|
          aug.match("#comment[. = 'SysRq setting']").should_not == []
          aug.match("#comment[. = 'kernel.sysrq: enables the SysRq feature']").should_not == []
        end
      end

      it "should remove comment" do
        apply!(Puppet::Type.type(:sysctl).new(
          :name     => "kernel.sysrq",
          :comment  => "",
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Sysctl.lns") do |aug|
          aug.match("#comment[. =~ regexp('kernel.sysrq:.*')]").should == []
          aug.match("#comment[. = 'SysRq setting']").should_not == []
        end
      end
    end
  end

  context "with small file" do
    let(:tmptarget) { aug_fixture("small") }
    let(:target) { tmptarget.path }

    describe "when updating comment" do
      it "should add comment" do
        apply!(Puppet::Type.type(:sysctl).new(
          :name     => "net.ipv4.ip_forward",
          :comment  => "test comment",
          :target   => target,
          :provider => "augeas"
        ))

        augparse(target, "Sysctl.lns", '
          { "#comment" = "Kernel sysctl configuration file" }
          { }
          { "#comment" = "For binary values, 0 is disabled, 1 is enabled.  See sysctl(8) and" }
          { "#comment" = "sysctl.conf(5) for more details." }
          { }
          { "#comment" = "Controls IP packet forwarding" }
          { "#comment" = "net.ipv4.ip_forward: test comment" }
          { "net.ipv4.ip_forward" = "0" }
          { }
        ')
      end
    end
  end

  context "with broken file" do
    let(:tmptarget) { aug_fixture("broken") }
    let(:target) { tmptarget.path }

    it "should fail to load" do
      txn = apply(Puppet::Type.type(:sysctl).new(
        :name     => "net.ipv4.ip_forward",
        :value    => "1",
        :target   => target,
        :provider => "augeas"
      ))

      txn.any_failed?.should_not == nil
      @logs.first.level.should == :err
      @logs.first.message.include?(target).should == true
    end
  end
end
