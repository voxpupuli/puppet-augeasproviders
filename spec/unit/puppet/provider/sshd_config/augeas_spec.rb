#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:sshd_config).provider(:augeas)

describe provider_class do
  before :each do
    FileTest.stubs(:exist?).returns false
    FileTest.stubs(:exist?).with('/etc/ssh/sshd_config').returns true
  end

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

    context "when declaring two resources with same key" do
      it "should fail with same name" do
        expect do 
          apply!(
            Puppet::Type.type(:sshd_config).new(
              :name      => "X11Forwarding",
              :value     => "no",
              :target    => target,
              :provider  => "augeas"
            ),
            Puppet::Type.type(:sshd_config).new(
              :name      => "X11Forwarding",
              :condition => "Host foo User root",
              :value     => "yes",
              :target    => target,
              :provider  => "augeas"
            )
          )
        end.to raise_error(Puppet::Resource::Catalog::DuplicateResourceError)
      end

      it "should fail with different names, same key and no conditions" do
        expect do 
          apply!(
            Puppet::Type.type(:sshd_config).new(
              :name      => "X11Forwarding",
              :value     => "no",
              :target    => target,
              :provider  => "augeas"
            ),
            Puppet::Type.type(:sshd_config).new(
              :name      => "Global X11Forwarding",
              :key       => "X11Forwarding",
              :value     => "yes",
              :target    => target,
              :provider  => "augeas"
            )
          )
        end.to raise_error
      end

      it "should not fail with different names, same key and different conditions" do
        expect do 
          apply!(
            Puppet::Type.type(:sshd_config).new(
              :name      => "X11Forwarding",
              :value     => "no",
              :target    => target,
              :provider  => "augeas"
            ),
            Puppet::Type.type(:sshd_config).new(
              :name      => "Global X11Forwarding",
              :key       => "X11Forwarding",
              :condition => "User foo",
              :value     => "yes",
              :target    => target,
              :provider  => "augeas"
            )
          )
        end.not_to raise_error
      end
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
          :value => p.get(:value),
          :condition => p.get(:condition),
        }
      }

      inst.size.should == 16
      inst[0].should == {:name=>"ListenAddress", :ensure=>:present, :value=>["0.0.0.0", "::"], :condition=>:absent}
      inst[1].should == {:name=>"SyslogFacility", :ensure=>:present, :value=>["AUTHPRIV"], :condition=>:absent}
      inst[2].should == {:name=>"AllowGroups", :ensure=>:present, :value=>["sshusers", "admins"], :condition=>:absent}
      inst[3].should == {:name=>"PermitRootLogin", :ensure=>:present, :value=>["without-password"], :condition=>:absent}
      inst[4].should == {:name=>"PasswordAuthentication", :ensure=>:present, :value=>["yes"], :condition=>:absent}
      inst[8].should == {:name=>"UsePAM", :ensure=>:present, :value=>["yes"], :condition=>:absent}
      inst[9].should == {:name=>"AcceptEnv", :ensure=>:present, :value=>["LANG", "LC_CTYPE", "LC_NUMERIC", "LC_TIME", "LC_COLLATE", "LC_MONETARY", "LC_MESSAGES", "LC_PAPER", "LC_NAME", "LC_ADDRESS", "LC_TELEPHONE", "LC_MEASUREMENT", "LC_IDENTIFICATION", "LC_ALL", "LANGUAGE", "XMODIFIERS"], :condition=>:absent}
      inst[12].should == {:name=>"X11Forwarding", :ensure=>:present, :value=>["no"], :condition=> "User anoncvs"}
      inst[15].should == {:name=>"AllowAgentForwarding", :ensure=>:present, :value=>["no"], :condition=> "Host *.example.net User *"}
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

      it "should add it next to commented out entry" do
        apply!(Puppet::Type.type(:sshd_config).new(
          :name     => "Banner",
          :value    => "/etc/issue",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Sshd.lns", '*[preceding-sibling::#comment[.="no default banner path"]][label()!="Match"]', '
          { "#comment" = "Banner none" }
          { "Banner" = "/etc/issue" }
          { "#comment" = "override default of no subsystems" }
          { "Subsystem"
            { "sftp" = "/usr/libexec/openssh/sftp-server" } }
          { "#comment" = "Example of overriding settings on a per-user basis" }
        ')
      end

      it "should create an array entry" do
        apply!(Puppet::Type.type(:sshd_config).new(
          :name     => "AllowUsers",
          :value    => ["ssh", "foo"],
          :target   => target,
          :provider => "augeas"
        ))
  
        aug_open(target, "Sshd.lns") do |aug|
          aug.get("AllowUsers/1").should == "ssh"
          aug.get("AllowUsers/2").should == "foo"
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

      it "should delete all instances of a setting" do
        expr = "ListenAddress"
        aug_open(target, "Sshd.lns") do |aug|
          aug.match(expr).should_not == []
        end

        apply!(Puppet::Type.type(:sshd_config).new(
          :name     => "ListenAddress",
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

      it "should replace and add to multiple single-value settings" do
        apply!(Puppet::Type.type(:sshd_config).new(
          :name     => "ListenAddress",
          :value    => ["192.168.1.1", "192.168.2.1", "192.168.3.1"],
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Sshd.lns") do |aug|
          aug.match("ListenAddress").size.should == 3
          aug.get("ListenAddress[1]").should == "192.168.1.1"
          aug.get("ListenAddress[2]").should == "192.168.2.1"
          aug.get("ListenAddress[3]").should == "192.168.3.1"
        end
      end

      it "should replace multiple single-value settings with one" do
        apply!(Puppet::Type.type(:sshd_config).new(
          :name     => "ListenAddress",
          :value    => "192.168.1.1",
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Sshd.lns") do |aug|
          aug.match("ListenAddress").size.should == 1
          aug.get("ListenAddress").should == "192.168.1.1"
        end
      end
    end
  end

  context "with no Match block file" do
    let(:tmptarget) { aug_fixture("nomatch") }
    let(:target) { tmptarget.path }

    describe "when creating settings" do
      it "should replace multiple single-value settings" do
        apply!(Puppet::Type.type(:sshd_config).new(
          :name     => "ListenAddress",
          :value    => ["192.168.1.1", "192.168.2.1", "192.168.3.1"],
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Sshd.lns") do |aug|
          aug.match("ListenAddress").size.should == 3
          aug.get("ListenAddress[1]").should == "192.168.1.1"
          aug.get("ListenAddress[2]").should == "192.168.2.1"
          aug.get("ListenAddress[3]").should == "192.168.3.1"
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

      it "should replace and add to multiple single-value settings" do
        apply!(Puppet::Type.type(:sshd_config).new(
          :name     => "ListenAddress",
          :value    => ["192.168.1.1", "192.168.2.1", "192.168.3.1"],
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Sshd.lns") do |aug|
          aug.match("ListenAddress").size.should == 3
          aug.get("ListenAddress[1]").should == "192.168.1.1"
          aug.get("ListenAddress[2]").should == "192.168.2.1"
          aug.get("ListenAddress[3]").should == "192.168.3.1"
        end
      end

      it "should replace multiple single-value settings with one" do
        apply!(Puppet::Type.type(:sshd_config).new(
          :name     => "ListenAddress",
          :value    => "192.168.1.1",
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Sshd.lns") do |aug|
          aug.match("ListenAddress").size.should == 1
          aug.get("ListenAddress").should == "192.168.1.1"
        end
      end

      it "should add it next to commented out entry" do
        apply!(Puppet::Type.type(:sshd_config).new(
          :name     => "Banner",
          :value    => "/etc/issue",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Sshd.lns", '*[preceding-sibling::#comment[.="no default banner path"]]', '
          { "#comment" = "Banner none" }
          { "Banner" = "/etc/issue" }
          { "#comment" = "override default of no subsystems" }
          { "Subsystem"
            { "sftp" = "/usr/libexec/openssh/sftp-server" } }
        ')
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
