#!/usr/bin/env rspec

require 'spec_helper'

FileTest.stubs(:exist?).returns false
FileTest.stubs(:exist?).with('/etc/rsyslog.conf').returns true
provider_class = Puppet::Type.type(:syslog).provider(:rsyslog)

describe provider_class do
  before :each do
    FileTest.stubs(:exist?).returns false
    FileTest.stubs(:exist?).with('/etc/rsyslog.conf').returns true
  end

  context "with empty file" do
    let(:tmptarget) { aug_fixture("empty") }
    let(:target) { tmptarget.path }

    it "should create simple new entry" do
      apply!(Puppet::Type.type(:syslog).new(
        :name        => "my test",
        :facility    => "local2",
        :level       => "*",
        :action_type => "file",
        :action      => "/var/log/test.log",
        :target      => target,
        :provider    => "rsyslog",
        :ensure      => "present"
      ))

      aug_open(target, "Rsyslog.lns") do |aug|
        aug.match("entry").size.should == 1
        aug.get("entry/action/file").should == "/var/log/test.log"
        aug.match("entry/action/no_sync").size.should == 0
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
          :facility => p.get(:facility),
          :level => p.get(:level),
          :no_sync => p.get(:no_sync),
          :action_type => p.get(:action_type),
          :action => p.get(:action),
        }
      }

      inst.size.should == 10
      inst[0].should == {:name=>"*.info /var/log/messages", :ensure=>:present, :facility=>"*", :level=>"info", :no_sync=>:false, :action_type=>"file", :action=>"/var/log/messages"}
      inst[1].should == {:name=>"mail.none /var/log/messages", :ensure=>:present, :facility=>"mail", :level=>"none", :no_sync=>:false, :action_type=>"file", :action=>"/var/log/messages"}
      inst[5].should == {:name=>"mail.* -/var/log/maillog", :ensure=>:present, :facility=>"mail", :level=>"*", :no_sync=>:true, :action_type=>"file", :action=>"/var/log/maillog"}
      inst[8].should == {:name=>"news.crit /var/log/spooler", :ensure=>:present, :facility=>"news", :level=>"crit", :no_sync=>:false, :action_type=>"file", :action=>"/var/log/spooler"}
      inst[9].should == {:name=>"local7.* /var/log/boot.log", :ensure=>:present, :facility=>"local7", :level=>"*", :no_sync=>:false, :action_type=>"file", :action=>"/var/log/boot.log"}
    end

    describe "when creating settings" do
      it "should create a simple new entry" do
        apply!(Puppet::Type.type(:syslog).new(
          :name        => "my test",
          :facility    => "local2",
          :level       => "info",
          :action_type => "file",
          :action      => "/var/log/test.log",
          :target      => target,
          :provider    => "rsyslog",
          :ensure      => "present"
        ))

        aug_open(target, "Rsyslog.lns") do |aug|
          aug.get("entry[selector/facility='local2']/action/file").should == "/var/log/test.log"
          aug.match("entry[selector/facility='local2']/action/no_sync").size.should == 0
        end
      end
    end

    describe "when modifying settings" do
      it "should add a no_sync flag" do
        apply!(Puppet::Type.type(:syslog).new(
          :name        => "cron.*",
          :facility    => "cron",
          :level       => "*",
          :action_type => "file",
          :action      => "/var/log/cron",
          :target      => target,
          :no_sync     => :true,
          :provider    => "rsyslog",
          :ensure      => "present"
        ))

        aug_open(target, "Rsyslog.lns") do |aug|
          aug.match("entry[selector/facility='cron']/action/no_sync").size.should == 1
        end
      end

      it "should remove the no_sync flag" do
        apply!(Puppet::Type.type(:syslog).new(
          :name        => "mail.*",
          :facility    => "mail",
          :level       => "*",
          :action_type => "file",
          :action      => "/var/log/maillog",
          :target      => target,
          :no_sync     => :false,
          :provider    => "rsyslog",
          :ensure      => "present"
        ))

        aug_open(target, "Rsyslog.lns") do |aug|
          aug.match("entry[selector/facility='mail']/action/no_sync").size.should == 0
        end
      end
    end

    describe "when removing settings" do
      it "should remove the entry" do
        apply!(Puppet::Type.type(:syslog).new(
          :name        => "mail.*",
          :facility    => "mail",
          :level       => "*",
          :action_type => "file",
          :action      => "/var/log/maillog",
          :target      => target,
          :provider    => "rsyslog",
          :ensure      => "absent"
        ))

        aug_open(target, "Rsyslog.lns") do |aug|
          aug.match("entry[selector/facility='mail' and level='*']").size.should == 0
        end
      end
    end
  end

  context "with broken file" do
    let(:tmptarget) { aug_fixture("broken") }
    let(:target) { tmptarget.path }

    it "should fail to load" do
      txn = apply(Puppet::Type.type(:syslog).new(
        :name        => "mail.*",
        :facility    => "mail",
        :level       => "*",
        :action_type => "file",
        :action      => "/var/log/maillog",
        :target      => target,
        :provider    => "rsyslog",
        :ensure      => "present"
      ))

      txn.any_failed?.should_not == nil
      @logs.first.level.should == :err
      @logs.first.message.include?(target).should == true
    end
  end
end
