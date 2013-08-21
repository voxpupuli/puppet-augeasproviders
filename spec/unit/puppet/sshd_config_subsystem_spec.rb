#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:sshd_config_subsystem).provider(:augeas)

describe provider_class do
  before :each do
    FileTest.stubs(:exist?).returns false
    FileTest.stubs(:exist?).with('/etc/ssh/sshd_config').returns true
  end

  context "with empty file" do
    let(:tmptarget) { aug_fixture("empty") }
    let(:target) { tmptarget.path }

    it "should create simple new entry" do
      apply!(Puppet::Type.type(:sshd_config_subsystem).new(
        :name     => "sftp",
        :command  => "/usr/lib/openssh/sftp-server",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Sshd.lns") do |aug|
        aug.get("Subsystem/sftp").should == "/usr/lib/openssh/sftp-server"
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
          :name    => p.get(:name),
          :ensure  => p.get(:ensure),
          :command => p.get(:command),
        }
      }

      inst.size.should == 1
      inst[0].should == {:name=>"sftp", :ensure=>:present,
	                 :command=>"/usr/libexec/openssh/sftp-server"}
    end

    describe "when creating settings" do
      it "should add it before Match block" do
        apply!(Puppet::Type.type(:sshd_config_subsystem).new(
          :name     => "mysub",
          :command  => "/bin/bash",
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Sshd.lns") do |aug|
          aug.get("Subsystem/mysub").should == "/bin/bash"
        end
      end
    end

    describe "when deleting settings" do
      it "should delete a setting" do
        expr = "Subsystem/sftp"
        aug_open(target, "Sshd.lns") do |aug|
          aug.match(expr).should_not == []
        end

        apply!(Puppet::Type.type(:sshd_config_subsystem).new(
          :name     => "sftp",
          :ensure   => "absent",
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Sshd.lns") do |aug|
          aug.match(expr).should == []
        end
      end
    end

    describe "when updating settings" do
      it "should replace a setting" do
        apply!(Puppet::Type.type(:sshd_config_subsystem).new(
          :name     => "sftp",
          :command  => "/bin/bash",
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Sshd.lns") do |aug|
          aug.get("Subsystem/sftp").should == "/bin/bash"
        end
      end
    end
  end

  context "with broken file" do
    let(:tmptarget) { aug_fixture("broken") }
    let(:target) { tmptarget.path }

    it "should fail to load" do
      txn = apply(Puppet::Type.type(:sshd_config_subsystem).new(
        :name     => "sftp",
        :command  => "/bin/bash",
        :target   => target,
        :provider => "augeas"
      ))

      txn.any_failed?.should_not == nil
      @logs.first.level.should == :err
      @logs.first.message.include?(target).should == true
    end
  end
end
