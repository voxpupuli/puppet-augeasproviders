#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:pam).provider(:augeas)

describe provider_class do
  before :each do
    FileTest.stubs(:exist?).returns false
  end

  context "with empty file" do
    let(:tmptarget) { aug_fixture("empty") }
    let(:target) { tmptarget.path }

    it "should create simple new entry" do
      apply!(Puppet::Type.type(:pam).new(
        :title       => "Add pam_test.so to auth for system-auth",
        :service     => "system-auth",
        :type        => "auth",
        :control     => "sufficient",
        :module      => "pam_test.so",
        :arguments   => "test_me_out",
        :position    => "before module pam_deny.so",
        :target      => target,
        :provider    => "augeas",
        :ensure      => "present"
      ))

      aug_open(target, "Pam.lns") do |aug|
        aug.get("./1/module").should == "pam_test.so"
        aug.get("./1/argument[1]").should == "test_me_out"
      end
    end

    it "should create simple new entry without arguments" do
      apply!(Puppet::Type.type(:pam).new(
        :title       => "Add pam_test.so to auth for system-auth",
        :service     => "system-auth",
        :type        => "auth",
        :control     => "sufficient",
        :module      => "pam_test.so",
        :target      => target,
        :provider    => "augeas",
        :ensure      => "present"
      ))

      aug_open(target, "Pam.lns") do |aug|
        aug.get("./1/module").should == "pam_test.so"
        aug.match("./1/argument").size.should == 0
      end
    end

    it "should create two new entries" do
      apply!(Puppet::Type.type(:pam).new(
        :title       => "Add pam_test.so to auth for system-auth",
        :service     => "system-auth",
        :type        => "auth",
        :control     => "sufficient",
        :module      => "pam_test.so",
        :arguments   => "test_me_out",
        :target      => target,
        :provider    => "augeas",
        :ensure      => "present"
      ))
      apply!(Puppet::Type.type(:pam).new(
        :title       => "Add pam_test.so to auth for system-auth",
        :service     => "system-auth",
        :type        => "auth",
        :control     => "required",
        :module      => "pam_unix.so",
        :arguments   => "broken_shadow",
        :target      => target,
        :provider    => "augeas",
        :ensure      => "present"
      ))

      aug_open(target, "Pam.lns") do |aug|
        aug.match("*[type='auth']").size.should == 2
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
          :ensure    => p.get(:ensure),
          :service   => p.get(:service),
          :type      => p.get(:type),
          :control   => p.get(:control),
          :module    => p.get(:module),
          :arguments => p.get(:arguments),
        }
      }

      inst.size.should == 21
      inst[0].should == {:ensure     => :present,
                         :service    => :absent,
                         :type       => "auth",
                         :control    => "required",
                         :module     => "pam_env.so",
                         :arguments  => [],}
      inst[1].should == {:ensure     => :present,
                         :service    => :absent,
                         :type       => "auth",
                         :control    => "sufficient",
                         :module     => "pam_unix.so",
                         :arguments  => ["nullok","try_first_pass"],}
      inst[5].should == {:ensure     => :present,
                         :service    => :absent,
                         :type       => "account",
                         :control    => "required",
                         :module     => "pam_unix.so",
                         :arguments  => ["broken_shadow"],}
      inst[8].should == {:ensure     => :present,
                         :service    => :absent,
                         :type       => "account",
                         :control    => "[default=bad success=ok user_unknown=ignore]",
                         :module     => "pam_sss.so",
                         :arguments  => [],}
      inst[10].should == {:ensure    => :present,
                          :service    => :absent,
                          :type      => "password",
                          :control   => "requisite",
                          :module    => "pam_pwquality.so",
                          :arguments => ["try_first_pass","retry=3","type="],}
    end

    describe "when creating settings" do
      it "should create simple new entry" do
        apply!(Puppet::Type.type(:pam).new(
          :title       => "Add pam_test.so to auth for system-auth",
          :service     => "system-auth",
          :type        => "auth",
          :control     => "sufficient",
          :module      => "pam_test.so",
          :arguments   => "test_me_out",
          :position    => "before module pam_deny.so",
          :target      => target,
          :provider    => "augeas",
          :ensure      => "present"
        ))

        aug_open(target, "Pam.lns") do |aug|
          aug.get("./5/module").should == "pam_test.so"
          aug.get("./5/argument[1]").should == "test_me_out"
        end
      end
    end

    describe "when modifying settings" do
      it "Changing the number of retries" do
        apply!(Puppet::Type.type(:pam).new(
          :title       => "Set retry count for pwquality",
          :service     => "system-auth",
          :type        => "password",
          :control     => "requisite",
          :module      => "pam_pwquality.so",
          :arguments   => ["try_first_pass","retry=4","type="],
          :target      => target,
          :provider    => "augeas",
          :ensure      => "present"
        ))

        aug_open(target, "Pam.lns") do |aug|
          aug.match('./*[type="password" and module="pam_pwquality.so" and argument="retry=4"]').size.should == 1
        end
      end

      it "should remove the type= argument" do
        apply!(Puppet::Type.type(:pam).new(
          :title       => "Remove type= from pwquality check",
          :service     => "system-auth",
          :type        => "password",
          :control     => "requisite",
          :module      => "pam_pwquality.so",
          :arguments   => ["try_first_pass","retry=4"],
          :target      => target,
          :provider    => "augeas",
          :ensure      => "present"
        ))

        aug_open(target, "Pam.lns") do |aug|
          aug.match('./*[type="password" and module="pam_pwquality.so" and argument="type="]').size.should == 0
        end
      end

      it "should change the value of control" do
        apply!(Puppet::Type.type(:pam).new(
          :title       => "Remove type= from pwquality check",
          :service     => "system-auth",
          :type        => "password",
          :control     => "required",
          :arguments   => ["try_first_pass","retry=4"],
          :module      => "pam_pwquality.so",
          :target      => target,
          :provider    => "augeas",
          :ensure      => "present"
        ))

        aug_open(target, "Pam.lns") do |aug|
          aug.get('./*[type="password" and module="pam_pwquality.so"]/control').should == "required"
        end
      end

      it "should add a new entry when control_is_param is true" do
        apply!(Puppet::Type.type(:pam).new(
          :title            => "Remove type= from pwquality check",
          :service          => "system-auth",
          :type             => "password",
          :control          => "sufficient",
          :control_is_param => true,
          :arguments        => ["try_first_pass","retry=4"],
          :module           => "pam_pwquality.so",
          :target           => target,
          :provider         => "augeas",
          :ensure           => "present"
        ))

        aug_open(target, "Pam.lns") do |aug|
          aug.match('./*[type="password" and module="pam_pwquality.so"]/control').size.should == 2
          aug.get('./*[type="password" and module="pam_pwquality.so"][1]/control').should == "requisite"
          aug.get('./*[type="password" and module="pam_pwquality.so"][2]/control').should == "sufficient"
        end
      end

      it "should update entry when control_is_param is true" do
        apply!(Puppet::Type.type(:pam).new(
          :title       => "Remove type= from pwquality check",
          :service     => "system-auth",
          :type        => "password",
          :control     => "requisite",
          :control_is_param => true,
          :arguments   => ["try_first_pass","retry=4"],
          :module      => "pam_pwquality.so",
          :target      => target,
          :provider    => "augeas",
          :ensure      => "present"
        ))

        aug_open(target, "Pam.lns") do |aug|
          aug.match('./*[type="password" and module="pam_pwquality.so"]/control').size.should == 1
          aug.get('./*[type="password" and module="pam_pwquality.so"]/control').should == "requisite"
        end
      end
    end

    describe "when removing settings" do
      it "should remove the entry" do
        apply!(Puppet::Type.type(:pam).new(
          :title       => "Remove pwquality entry",
          :service     => "system-auth",
          :type        => "password",
          :control     => "requisite",
          :module      => "pam_pwquality.so",
          :arguments   => ["try_first_pass","retry=4"],
          :target      => target,
          :provider    => "augeas",
          :ensure      => "absent"
        ))

        aug_open(target, "Pam.lns") do |aug|
          aug.match('./*[type="password" and module="pam_pwquality.so"]').size.should == 0
        end
      end
    end
  end

  context "with broken file" do
    let(:tmptarget) { aug_fixture("broken") }
    let(:target) { tmptarget.path }

    it "should fail to load" do
      txn = apply(Puppet::Type.type(:pam).new(
        :title       => "Ensure pwquality is configured",
        :service     => "system-auth",
        :type        => "password",
        :control     => "requisite",
        :module      => "pam_pwquality.so",
        :arguments   => ["try_first_pass","retry=3","type="],
        :target      => target,
        :provider    => "augeas",
        :ensure      => "present"
      ))

      txn.any_failed?.should_not == nil
      @logs.first.level.should == :err
      @logs.first.message.include?(target).should == true
    end
  end
end
