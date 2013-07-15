#!/usr/bin/env rspec

require 'spec_helper'

FileTest.stubs(:exist?).returns false
# Since it can be any number of files, what do you do?
#FileTest.stubs(:exist?).with('/etc/').returns true
provider_class = Puppet::Type.type(:pam).provider(:pam)

describe provider_class do
  before :each do
    FileTest.stubs(:exist?).returns false
    FileTest.stubs(:exist?).with('/etc/rsyslog.conf').returns true
  end

  context "with empty file" do
    let(:tmptarget) { aug_fixture("empty") }
    let(:target) { tmptarget.path }

    it "should create simple new entry" do
      apply!(Puppet::Type.type(:pam).new(
        :service     => "system-auth-ac",
        :type        => "auth",
        :control     => "sufficient",
        :module      => "pam_test.so",
        :arguments   => "test_me_out",
        :order       => "before module pam_deny.so",
        :target      => target,
        :provider    => "pam",
        :ensure      => "present"
      ))

      aug_open(target, "Pam.lns") do |aug|
        aug.get("./1/module").should == "pam_test.so"
        aug.get("./1/module/argument[1]").should == "test_me_out"
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
          :ensure => p.get(:ensure),
          :service => p.get(:service),
          :type     => p.get(:type),
          :control => p.get(:control),
          :module  => p.get(:module),
          :arguements => p.get(:arguments),
        }
      }

      inst.size.should == 21
      inst[0].should == {:ensure     => :present,
                         :type       => "auth",
                         :control    => "required",
                         :module     => "pam_env.so",
                         :arguments  => :absent,}
      inst[1].should == {:ensure     => :present,
                         :type       => "auth",
                         :control    => "sufficient",
                         :module     => "pam_unix.so",
                         :arguments  => ["nullok","try_first_pass"],}
      inst[6].should == {:ensure     => :present,
                         :type       => "account",
                         :control    => "required",
                         :module     => "pam_unix.so",
                         :arguments  => ["broken_shadow"],}
      inst[9].should == {:ensure     => :present,
                         :type       => "account",
                         :control    => "[default=bad success=ok user_unknown=ignore]",
                         :module     => "pam_sss.so",
                         :arguments  => :absent,}
      inst[11].should == {:ensure    => :present,
                          :type      => "password",
                          :control   => "requisite",
                          :module    => "pam_pwquality.so",
                          :arguments => ["try_first_pass","retry=3","type="],}
    end

    describe "when creating settings" do
    it "should create simple new entry" do
      apply!(Puppet::Type.type(:pam).new(
        :service     => "system-auth-ac",
        :type        => "auth",
        :control     => "sufficient",
        :module      => "pam_test.so",
        :arguments   => "test_me_out",
        :order       => "before module pam_deny.so",
        :target      => target,
        :provider    => "pam",
        :ensure      => "present"
      ))

      aug_open(target, "Pam.lns") do |aug|
        aug.get("./1/module").should == "pam_test.so"
        aug.get("./1/module/argument[1]").should == "test_me_out"
      end
    end

    describe "when modifying settings" do
      it "Changing the number of retries" do
        apply!(Puppet::Type.type(:pam).new(
          :service     => "system-auth-ac",
          :type        => "password",
          :control     => "requisite",
          :module      => "pam_pwquality.so",
          :arguments   => ["try_first_pass","retry=4","type="],
          :target      => target,
          :provider    => "pam",
          :ensure      => "present"
        ))

        aug_open(target, "Pam.lns") do |aug|
# TODO: this match may be broken on argument
          aug.get('./*[type="password" and module="pam_pwquality.so" and argument="retry=4"]').size.should == 1
        end
      end

      it "should remove the type= argument" do
        apply!(Puppet::Type.type(:pam).new(
          :service     => "system-auth-ac",
          :type        => "password",
          :control     => "requisite",
          :module      => "pam_pwquality.so",
          :arguments   => ["try_first_pass","retry=4"],
          :target      => target,
          :provider    => "pam",
          :ensure      => "present"
        ))

        aug_open(target, "Pam.lns") do |aug|
# TODO: this match may be broken on argument
          aug.get('./*[type="password" and module="pam_pwquality.so" and argument="type="]').size.should == 0
        end
      end
    end

    describe "when removing settings" do
        apply!(Puppet::Type.type(:pam).new(
          :service     => "system-auth-ac",
          :type        => "password",
          :control     => "requisite",
          :module      => "pam_pwquality.so",
          :arguments   => ["try_first_pass","retry=4"],
          :target      => target,
          :provider    => "pam",
          :ensure      => "absent"
        ))

        aug_open(target, "Pam.lns") do |aug|
          aug.get('./*[type="password" and module="pam_pwquality.so"]').size.should == 0
        end
      end
    end
  end

  context "with broken file" do
    let(:tmptarget) { aug_fixture("broken") }
    let(:target) { tmptarget.path }

    it "should fail to load" do
      txn = apply!(Puppet::Type.type(:pam).new(
        :service     => "system-auth-ac",
        :type        => "password",
        :control     => "requisite",
        :module      => "pam_pwquality.so",
        :arguments   => ["try_first_pass","retry=3","type="],
        :target      => target,
        :provider    => "pam",
        :ensure      => "present"
      ))

      txn.any_failed?.should_not == nil
      @logs.first.level.should == :err
      @logs.first.message.include?(target).should == true
    end
  end
end
