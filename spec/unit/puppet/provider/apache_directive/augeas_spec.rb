#!/usr/bin/env rspec

require 'spec_helper'

FileTest.stubs(:exist?).returns false
FileTest.stubs(:exist?).with('/etc/apache2/apache2.conf').returns true
provider_class = Puppet::Type.type(:apache_directive).provider(:augeas)

describe provider_class do
  before :each do
    FileTest.stubs(:exist?).returns false
    Facter.fact(:osfamily).stubs(:value).returns 'Debian'
    FileTest.stubs(:exist?).with('/etc/apache2/apache2.conf').returns true
  end

  context "with empty file" do
    let(:tmptarget) { aug_fixture("empty") }
    let(:target) { tmptarget.path }

    it "should create simple new entry" do
      apply!(Puppet::Type.type(:apache_directive).new(
        :name     => 'StartServers',
        :args     => '3',
        :ensure   => "present",
        :target   => target,
        :provider => 'augeas'
      ))

      augparse(target, "Httpd.lns", '{ "directive" = "StartServers" { "arg" = "3" } }')
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
          :args => p.get(:args),
          :context => p.get(:context)
        }
      }

      inst.size.should == 49
      inst[0].should == {:args=>["${APACHE_LOCK_DIR}/accept.lock"], :name=>"LockFile", :ensure=>:present, :context=>""}
      inst[5].should == {:args=>["5"], :name=>"KeepAliveTimeout", :ensure=>:present, :context=>""}
      inst[30].should == {:args=>["150"], :context=>"IfModule[1]", :name=>"MaxClients", :ensure=>:present}
    end
  end

  context "with simple file" do
    let(:tmptarget) { aug_fixture("simple") }
    let(:target) { tmptarget.path }

    it "should create simple new entry" do
      apply!(Puppet::Type.type(:apache_directive).new(
        :name     => 'StartServers',
        :args     => '3',
        :ensure   => "present",
        :target   => target,
        :provider => 'augeas'
      ))

      # New entry gets added next to existing SetEnv entries
      augparse(target, "Httpd.lns", '
        { "directive" = "SetEnv" { "arg" = "TEST" } }
        { "directive" = "SetEnv" { "arg" = "FQDN" } { "arg" = "ignored" } }
        { "directive" = "SetEnv" { "arg" = "FQDN" } { "arg" = "test.com" } }
        { "directive" = "Example" }
        { "directive" = "StartServers" { "arg" = "3" } }
      ')
    end

    context "when updating existing" do
      it "should update existing" do
        apply!(Puppet::Type.type(:apache_directive).new(
          :name     => 'Timeout',
          :args     => '0',
          :ensure   => "present",
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Httpd.lns") do |aug|
          aug.get("directive[.='Timeout']/arg").should == '0'
        end
      end

      it "should clear args when only one arg" do
        apply!(Puppet::Type.type(:apache_directive).new(
          :name        => 'SetEnv',
          :args        => ['FQDN'],
          :args_params => 1,
          :ensure      => "present",
          :target      => target,
          :provider    => "augeas"
        ))
        augparse(target, "Httpd.lns", '
          { "directive" = "SetEnv" { "arg" = "TEST" } }
          { "directive" = "SetEnv" { "arg" = "FQDN" } }
          { "directive" = "Example" }
        ')
      end
    end

    context "when creating with context" do
      it "creating should create directive" do
        apply!(Puppet::Type.type(:apache_directive).new(
          :name        => 'StartServers',
          :args_params => 0,
          :args        => ['2'],
          :context     => "IfModule[1]",
          :ensure      => "present",
          :target      => target,
          :provider    => "augeas"
        ))

        augparse(target, "Httpd.lns", '
          { "directive" = "SetEnv" { "arg" = "TEST" } }
          { "directive" = "SetEnv" { "arg" = "FQDN" } { "arg" = "ignored" } }
          { "directive" = "SetEnv" { "arg" = "FQDN" } { "arg" = "test.com" } }
          { "directive" = "Example" }
          { "IfModule" { "directive" = "StartServers" { "arg" = "2" } } }
        ')
        aug_open(target, "Httpd.lns") do |aug|
          aug.get("IfModule[1]/directive[.='StartServers']/arg").should == '2'
        end
      end
    end

    it "should delete entries" do
      apply!(Puppet::Type.type(:apache_directive).new(
        :name     => 'Timeout',
        :args     => '0',
        :ensure   => "absent",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Httpd.lns") do |aug|
        aug.match("directive[.='Timeout']").size.should == 0
      end
    end
  end

  context "with full file" do
    let(:tmptarget) { aug_fixture("full") }
    let(:target) { tmptarget.path }

    context "when using context" do
      it "updating should update value" do
        apply!(Puppet::Type.type(:apache_directive).new(
          :name        => 'StartServers',
          :args_params => 0,
          :args        => 2,
          :context     => "IfModule[arg='mpm_worker_module']",
          :ensure      => "present",
          :target      => target,
          :provider    => "augeas"
        ))

        aug_open(target, "Httpd.lns") do |aug|
          aug.get("IfModule[arg='mpm_worker_module']/directive[.='StartServers']/arg").should == '2'
        end
      end
    end
  end


  context "with broken file" do
    let(:tmptarget) { aug_fixture("broken") }
    let(:target) { tmptarget.path }

    it "should fail to load" do
      txn = apply(Puppet::Type.type(:apache_directive).new(
        :name     => 'SetEnv',
        :args     => ['FQDN', 'test.com'],
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
