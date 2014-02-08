#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:nrpe_command).provider(:augeas)

describe provider_class do
  context "with empty file" do
    let(:tmptarget) { aug_fixture("empty") }
    let(:target) { tmptarget.path }

    it "should create new entry" do
      apply!(Puppet::Type.type(:nrpe_command).new(
        :name     => "check_spec_test",
        :command    => "/usr/bin/check_my_thing -p 'some command with \"multiple [types]\" of quotes' -x and-stuff",
        :target   => target,
        :provider => "augeas"
      ))

      augparse(target, "Nrpe.lns", '
        { "command"
          { "check_spec_test" = "/usr/bin/check_my_thing -p \'some command with \"multiple [types]\" of quotes\' -x and-stuff" }
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
          :command => p.get(:command),
        }
      }

      inst.size.should == 6
      inst[0].should == {:name=>"check_users", :ensure=>:present, :command=>"/usr/lib/nagios/plugins/check_users -w 5 -c 10" }
      inst[1].should == {:name=>"check_load", :ensure=>:present, :command=>"/usr/lib/nagios/plugins/check_load -w 15,10,5 -c 30,25,20" }
      inst[2].should == {:name=>"check_hda1", :ensure=>:present, :command=>"/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p /dev/hda1" }
      inst[3].should == {:name=>"check_zombie_procs", :ensure=>:present, :command=>"/usr/lib/nagios/plugins/check_procs -w 5 -c 10 -s Z" }
      inst[4].should == {:name=>"check_total_procs", :ensure=>:present, :command=>"/usr/lib/nagios/plugins/check_procs -w 150 -c 200 " }
      inst[5].should == {:name=>"check_test", :ensure=>:present, :command=>"/usr/lib/nagios/plugins/check_http -I 127.0.0.1 -p 8080 -u /ubrowse.action?acro=SCGC-ENS" }
    end

    it "should delete entries" do
      apply!(Puppet::Type.type(:nrpe_command).new(
        :name     => "check_test",
        :ensure   => "absent",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Nrpe.lns") do |aug|
        aug.match("command/check_test").size.should == 0
      end
    end

    it "should update value" do
      apply!(Puppet::Type.type(:nrpe_command).new(
        :name     => "check_users",
        :command  => "/usr/lib/nagios/plugins/check_users -w 10 -c 20",
        :target   => target,
        :provider => "augeas"
      ))

      augparse_filter(target, "Nrpe.lns", "command[check_users]", '
        { "command"
          { "check_users" = "/usr/lib/nagios/plugins/check_users -w 10 -c 20" }
        }
      ')
    end

    it "should create new entry" do
      apply!(Puppet::Type.type(:nrpe_command).new(
        :name     => "check_spec_test",
        :command    => "/usr/bin/check_my_thing -p 'some command with \"multiple [types]\" of quotes' -x and-stuff",
        :target   => target,
        :provider => "augeas"
      ))

      augparse_filter(target, "Nrpe.lns", "command[check_spec_test]", '
        { "command"
          { "check_spec_test" = "/usr/bin/check_my_thing -p \'some command with \"multiple [types]\" of quotes\' -x and-stuff" }
        }
      ')
    end
  end

  context "with broken file" do
    let(:tmptarget) { aug_fixture("broken") }
    let(:target) { tmptarget.path }

    it "should fail to load" do
      txn = apply(Puppet::Type.type(:nrpe_command).new(
        :name     => "check_this",
        :command    => "/usr/bin/mycheck -w this",
        :target   => target,
        :provider => "augeas"
      ))

      txn.any_failed?.should_not == nil
      @logs.first.level.should == :err
      @logs.first.message.include?(target).should == true
    end
  end
end
