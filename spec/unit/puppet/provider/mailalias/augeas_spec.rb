#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:mailalias).provider(:augeas)

describe provider_class do
  before :each do
    FileTest.stubs(:exist?).returns false
    FileTest.stubs(:exist?).with('/etc/aliases').returns true
  end

  context "with empty file" do
    let(:tmptarget) { aug_fixture("empty") }
    let(:target) { tmptarget.path }

    it "should create simple new entry" do
      apply!(Puppet::Type.type(:mailalias).new(
        :name      => "foo",
        :recipient => "bar",
        :target    => target,
        :provider  => "augeas"
      ))

      aug_open(target, "Aliases.lns") do |aug|
        aug.get("./1/name").should == "foo"
        aug.get("./1/value").should == "bar"
      end
    end

    it "should create new entry" do
      apply!(Puppet::Type.type(:mailalias).new(
        :name      => "foo",
        :recipient => [ "foo-a", "foo-b" ],
        :target    => target,
        :provider  => "augeas"
      ))

      aug_open(target, "Aliases.lns") do |aug|
        aug.get("./1/name").should == "foo"
        aug.match("./1/value").size.should == 2
        aug.get("./1/value[1]").should == "foo-a"
        aug.get("./1/value[2]").should == "foo-b"
      end
    end

    # Ticket #41
    it "should create new entry with quotes" do
      apply!(Puppet::Type.type(:mailalias).new(
        :name      => "users-leave",
        :recipient => "| /var/lib/mailman/mail/mailman leave users",
        :target    => target,
        :provider  => "augeas"
      ))

      aug_open(target, "Aliases.lns") do |aug|
        aug.get("./1/name").should == "users-leave"
        aug.get("./1/value").should == "\"| /var/lib/mailman/mail/mailman leave users\""
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
          :recipient => p.get(:recipient),
        }
      }

      inst.size.should == 4
      inst[0].should == {:name=>"mailer-daemon", :ensure=>:present, :recipient=>["postmaster"]}
      inst[1].should == {:name=>"postmaster", :ensure=>:present, :recipient=>["root"]}
      inst[2].should == {:name=>"test", :ensure=>:present, :recipient=>["user1", "user2"]}
    end

    it "should delete entries" do
      apply!(Puppet::Type.type(:mailalias).new(
        :name     => "mailer-daemon",
        :ensure   => "absent",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Aliases.lns") do |aug|
        aug.match("*[name = 'mailer-daemon']").should == []
      end
    end

    describe "when updating recipients" do
      it "should replace a recipients" do
        apply!(Puppet::Type.type(:mailalias).new(
          :name      => "mailer-daemon",
          :recipient => [ "test" ],
          :target    => target,
          :provider  => "augeas"
        ))

        aug_open(target, "Aliases.lns") do |aug|
          aug.get("./1/name").should == "mailer-daemon"
          aug.match("./1/value").size.should == 1
          aug.get("./1/value").should == "test"
        end
      end

      it "should add multiple recipients" do
        apply!(Puppet::Type.type(:mailalias).new(
          :name      => "mailer-daemon",
          :recipient => [ "test-a", "test-b" ],
          :target    => target,
          :provider  => "augeas"
        ))

        aug_open(target, "Aliases.lns") do |aug|
          aug.get("./1/name").should == "mailer-daemon"
          aug.match("./1/value").size.should == 2
          aug.get("./1/value[1]").should == "test-a"
          aug.get("./1/value[2]").should == "test-b"
        end
      end

      # Ticket #41
      it "should update entry with quotes" do
        apply!(Puppet::Type.type(:mailalias).new(
          :name      => "users-leave",
          :recipient => "| /var/lib/mailman/mail/mailman leave userss",
          :target    => target,
          :provider  => "augeas"
        ))

        aug_open(target, "Aliases.lns") do |aug|
          aug.get("./4/name").should == "users-leave"
          aug.get("./4/value").should == "\"| /var/lib/mailman/mail/mailman leave userss\""
        end
      end
    end
  end

  context "with broken file" do
    let(:tmptarget) { aug_fixture("broken") }
    let(:target) { tmptarget.path }

    it "should fail to load" do
      txn = apply(Puppet::Type.type(:mailalias).new(
        :name      => "foo",
        :recipient => "bar",
        :target    => target,
        :provider  => "augeas"
      ))

      txn.any_failed?.should_not == nil
      @logs.first.level.should == :err
      @logs.first.message.include?(target).should == true
    end
  end
end
