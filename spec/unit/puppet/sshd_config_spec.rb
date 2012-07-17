#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:sshd_config).provider(:augeas)

describe provider_class do
  context "with empty file" do
    let(:tmptarget) { aug_fixture("empty") }
    let(:target) { tmptarget.path }

    it "should create simple new entry" do
      apply!(Puppet::Type.type(:sshd_config).new(
        :name     => "PermitRootLogin",
        :value    => "yes",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Sshd.lns") do |aug|
        aug.get("PermitRootLogin").should == "yes"
      end
    end

    it "should create an array entry" do
      apply!(Puppet::Type.type(:sshd_config).new(
        :name     => "AllowGroups",
        :value    => ["sshgroups", "admins"],
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Sshd.lns") do |aug|
        aug.get("AllowGroups/1").should == "sshgroups"
        aug.get("AllowGroups/2").should == "admins"
      end
    end

    it "should create new entry in a Match block" do
      apply!(Puppet::Type.type(:sshd_config).new(
        :name      => "X11Forwarding",
        :condition => "Host foo User root",
        :value     => "yes",
        :target    => target,
        :provider  => "augeas"
      ))

      aug_open(target, "Sshd.lns") do |aug|
        aug.get("Match[1]/Condition/Host").should == "foo"
        aug.get("Match[1]/Condition/User").should == "root"
        aug.get("Match[1]/Settings/X11Forwarding").should == "yes"
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
          :value => p.get(:value),
          :condition => p.get(:condition),
        }
      }

      inst.size.should == 18
      inst[0].should == {:name=>"SyslogFacility", :ensure=>:present, :value=>["AUTHPRIV"], :condition=>:absent}
      inst[1].should == {:name=>"AllowGroups", :ensure=>:present, :value=>["sshusers", "admins"], :condition=>:absent}
      inst[2].should == {:name=>"PermitRootLogin", :ensure=>:present, :value=>["without-password"], :condition=>:absent}
      inst[3].should == {:name=>"PasswordAuthentication", :ensure=>:present, :value=>["yes"], :condition=>:absent}
      inst[7].should == {:name=>"UsePAM", :ensure=>:present, :value=>["yes"], :condition=>:absent}
      inst[8].should == {:name=>"AcceptEnv", :ensure=>:present, :value=>["LANG", "LC_CTYPE", "LC_NUMERIC", "LC_TIME", "LC_COLLATE", "LC_MONETARY", "LC_MESSAGES"], :condition=>:absent}
      inst[14].should == {:name=>"X11Forwarding", :ensure=>:present, :value=>["no"], :condition=> "User anoncvs"}
      inst[17].should == {:name=>"AllowAgentForwarding", :ensure=>:present, :value=>["no"], :condition=> "Host *.example.net User *"}
    end

    describe "when creating settings" do
      it "should add it before Match block" do
        apply!(Puppet::Type.type(:sshd_config).new(
          :name     => "Banner",
          :value    => "/etc/issue",
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Sshd.lns") do |aug|
          aug.get("Banner").should == "/etc/issue"
        end
      end

      it "should match the entire Match conditions and create new block" do
        apply!(Puppet::Type.type(:sshd_config).new(
          :name      => "AllowAgentForwarding",
          :condition => "Host *.example.net",
          :value     => "yes",
          :target    => target,
          :provider  => "augeas"
        ))

        aug_open(target, "Sshd.lns") do |aug|
          aug.get("Match[3]/Settings/AllowAgentForwarding").should == "yes"
        end
      end

      it "should replace the array setting" do
        apply!(Puppet::Type.type(:sshd_config).new(
          :name     => "AcceptEnv",
          :value    => ["BAR", "LC_FOO"],
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Sshd.lns") do |aug|
          aug.match("AcceptEnv/*").size.should == 2
          aug.get("AcceptEnv/1").should == "BAR"
          aug.get("AcceptEnv/2").should == "LC_FOO"
        end
      end
    end

    describe "when deleting settings" do
      it "should delete a setting" do
        expr = "PermitRootLogin"
        aug_open(target, "Sshd.lns") do |aug|
          aug.match(expr).should_not == []
        end

        apply!(Puppet::Type.type(:sshd_config).new(
          :name     => "PermitRootLogin",
          :ensure   => "absent",
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Sshd.lns") do |aug|
          aug.match(expr).should == []
        end
      end

      it "should delete from a Match block" do
        expr = "Match[*]/Settings/AllowAgentForwarding"
        aug_open(target, "Sshd.lns") do |aug|
          aug.match(expr).should_not == []
        end

        apply!(Puppet::Type.type(:sshd_config).new(
          :name      => "AllowAgentForwarding",
          :condition => "Host *.example.net User *",
          :ensure    => "absent",
          :target    => target,
          :provider  => "augeas"
        ))

        aug_open(target, "Sshd.lns") do |aug|
          aug.match(expr).should == []
        end
      end
    end

    describe "when updating settings" do
      it "should replace a setting" do
        apply!(Puppet::Type.type(:sshd_config).new(
          :name     => "PermitRootLogin",
          :value    => "yes",
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Sshd.lns") do |aug|
          aug.match("*[label()='PermitRootLogin']").size.should == 1
          aug.get("PermitRootLogin").should == "yes"
        end
      end

      it "should replace a setting in a Match block" do
        apply!(Puppet::Type.type(:sshd_config).new(
          :name      => "X11Forwarding",
          :condition => "User anoncvs",
          :value     => "yes",
          :target    => target,
          :provider  => "augeas"
        ))

        aug_open(target, "Sshd.lns") do |aug|
          aug.get("Match[*]/Settings/X11Forwarding").should == "yes"
        end
      end
    end
  end

  context "with broken file" do
    let(:tmptarget) { aug_fixture("broken") }
    let(:target) { tmptarget.path }

    it "should fail to load" do
      txn = apply(Puppet::Type.type(:sshd_config).new(
        :name     => "PermitRootLogin",
        :value    => "yes",
        :target   => target,
        :provider => "augeas"
      ))

      txn.any_failed?.should_not == nil
      @logs.first.level.should == :err
      @logs.first.message.include?(target).should == true
    end
  end
end
