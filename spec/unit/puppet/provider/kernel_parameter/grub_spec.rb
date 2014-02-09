#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:kernel_parameter).provider(:grub)

describe provider_class do
  before :each do
    provider_class.stubs(:default?).returns(true)
    FileTest.stubs(:exist?).returns false
    FileTest.stubs(:executable?).returns false
    FileTest.stubs(:exist?).with('/boot/grub/menu.lst').returns true
  end

  describe "when finding GRUB config" do
    it "should find EFI config when present" do
      FileTest.stubs(:exist?).with('/boot/efi/EFI/redhat/grub.conf').returns true
      provider_class.target.should == '/boot/efi/EFI/redhat/grub.conf'
    end

    it "should default to BIOS config" do
      FileTest.stubs(:exist?).with('/boot/efi/EFI/redhat/grub.conf').returns false
      provider_class.target.should == '/boot/grub/menu.lst'
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
          :bootmode => p.get(:bootmode),
        }
      }

      inst.size.should == 8
      inst[0].should == {:name=>"ro", :ensure=>:present, :value=>:absent, :bootmode=>:all}
      inst[1].should == {:name=>"root", :ensure=>:present, :value=>"/dev/VolGroup00/LogVol00", :bootmode=>:all}
      inst[2].should == {:name=>"rhgb", :ensure=>:present, :value=>:absent, :bootmode=>:normal}
      inst[3].should == {:name=>"quiet", :ensure=>:present, :value=>:absent, :bootmode=>:normal}
      inst[4].should == {:name=>"elevator", :ensure=>:present, :value=>"noop", :bootmode=>:all}
      inst[5].should == {:name=>"divider", :ensure=>:present, :value=>"10", :bootmode=>:all}
      inst[6].should == {:name=>"rd_LVM_LV", :ensure=>:present, :value=>["vg/lv1", "vg/lv2"], :bootmode=>:normal}
      inst[7].should == {:name=>"S", :ensure=>:present, :value=>:absent, :bootmode=>:recovery}
    end

    describe "when creating entries" do
      it "should create no-value entries" do
        apply!(Puppet::Type.type(:kernel_parameter).new(
          :name     => "foo",
          :ensure   => :present,
          :target   => target,
          :provider => "grub"
        ))

        aug_open(target, "Grub.lns") do |aug|
          aug.match("title/kernel/foo").size.should == 3
          aug.match("title/kernel/foo").map {|p| aug.get(p)}.should == [nil]*3
        end
      end

      it "should create entry with value" do
        apply!(Puppet::Type.type(:kernel_parameter).new(
          :name     => "foo",
          :ensure   => :present,
          :value    => "bar",
          :target   => target,
          :provider => "grub"
        ))

        aug_open(target, "Grub.lns") do |aug|
          aug.match("title/kernel/foo").size.should == 3
          aug.match("title/kernel/foo").map {|p| aug.get(p)}.should == ["bar"]*3
        end
      end

      it "should create entries with multiple values" do
        apply!(Puppet::Type.type(:kernel_parameter).new(
          :name     => "foo",
          :ensure   => :present,
          :value    => ["bar", "baz"],
          :target   => target,
          :provider => "grub"
        ))

        aug_open(target, "Grub.lns") do |aug|
          aug.match("title/kernel/foo").size.should == 6
          aug.match("title/kernel/foo").map {|p| aug.get(p)}.should == ["bar", "baz"]*3
        end
      end

      # This is a "create" because rd_LVM_LV only exists on one entry in the
      # fixture.  If it was on all, it would be a modification.
      it "should change existing values if present" do
        apply!(Puppet::Type.type(:kernel_parameter).new(
          :name     => "rd_LVM_LV",
          :ensure   => :present,
          :value    => ["vg/lv7", "vg/lv8", "vg/lv9"],
          :target   => target,
          :provider => "grub"
        ))

        aug_open(target, "Grub.lns") do |aug|
          aug.match("title/kernel/rd_LVM_LV").size.should == 9
          aug.match("title/kernel/rd_LVM_LV[.='vg/lv1']").size.should == 0
          aug.match("title/kernel/rd_LVM_LV[.='vg/lv2']").size.should == 0
          aug.match("title/kernel/rd_LVM_LV").map {|p| aug.get(p)}.should == ["vg/lv7", "vg/lv8", "vg/lv9"]*3
        end
      end

      it "should remove existing values if too many" do
        apply!(Puppet::Type.type(:kernel_parameter).new(
          :name     => "rd_LVM_LV",
          :ensure   => :present,
          :value    => ["vg/lv7"],
          :target   => target,
          :provider => "grub"
        ))

        aug_open(target, "Grub.lns") do |aug|
          aug.match("title/kernel/rd_LVM_LV").size.should == 3
          aug.match("title/kernel/rd_LVM_LV[.='vg/lv1']").size.should == 0
          aug.match("title/kernel/rd_LVM_LV[.='vg/lv2']").size.should == 0
          aug.match("title/kernel/rd_LVM_LV").map {|p| aug.get(p)}.should == ["vg/lv7"]*3
        end
      end

      it "should create recovery-only entries" do
        apply!(Puppet::Type.type(:kernel_parameter).new(
          :name     => "foo",
          :ensure   => :present,
          :bootmode => :recovery,
          :target   => target,
          :provider => "grub"
        ))

        aug_open(target, "Grub.lns") do |aug|
          aug.match("title/kernel/foo").size.should == 1
          aug.match("title[2]/kernel/foo").size.should == 1
        end
      end

      it "should create normal boot-only entries" do
        apply!(Puppet::Type.type(:kernel_parameter).new(
          :name     => "foo",
          :ensure   => :present,
          :bootmode => :normal,
          :target   => target,
          :provider => "grub"
        ))

        aug_open(target, "Grub.lns") do |aug|
          aug.match("title/kernel/foo").size.should == 2
          aug.match("title[1]/kernel/foo").size.should == 1
          aug.match("title[3]/kernel/foo").size.should == 1
        end
      end
    end

    describe "when deleting entries" do
      it "should delete entries when present on all resources" do
        apply!(Puppet::Type.type(:kernel_parameter).new(
          :name     => "divider",
          :ensure   => "absent",
          :target   => target,
          :provider => "grub"
        ))

        aug_open(target, "Grub.lns") do |aug|
          aug.match("title/kernel/divider").should == []
        end
      end

      # rd_LVM_LV only exists on one entry in the fixture
      it "should delete entries if partially present" do
        apply!(Puppet::Type.type(:kernel_parameter).new(
          :name     => "rd_LVM_LV",
          :ensure   => :absent,
          :target   => target,
          :provider => "grub"
        ))

        aug_open(target, "Grub.lns") do |aug|
          aug.match("title/kernel/rd_LVM_LV").size.should == 0
        end
      end
    end

    describe "when modifying values" do
      before :each do
        provider_class.any_instance.stubs(:create).never
      end

      it "should change existing values" do
        apply!(Puppet::Type.type(:kernel_parameter).new(
          :name     => "elevator",
          :ensure   => :present,
          :value    => "deadline",
          :target   => target,
          :provider => "grub"
        ))

        aug_open(target, "Grub.lns") do |aug|
          aug.match("title/kernel/elevator").size.should == 3
          aug.match("title/kernel/elevator").map {|p| aug.get(p)}.should == ["deadline"]*3
        end
      end

      it "should add value to entry" do
        apply!(Puppet::Type.type(:kernel_parameter).new(
          :name     => "ro",
          :ensure   => :present,
          :value    => "foo",
          :target   => target,
          :provider => "grub"
        ))

        aug_open(target, "Grub.lns") do |aug|
          aug.match("title/kernel/ro").size.should == 3
          aug.match("title/kernel/ro").map {|p| aug.get(p)}.should == ["foo"]*3
        end
      end

      it "should add entries for multiple values" do
        apply!(Puppet::Type.type(:kernel_parameter).new(
          :name     => "elevator",
          :ensure   => :present,
          :value    => ["noop", "deadline"],
          :target   => target,
          :provider => "grub"
        ))

        aug_open(target, "Grub.lns") do |aug|
          aug.match("title/kernel/elevator").size.should == 6
          aug.match("title/kernel/elevator").map {|p| aug.get(p)}.should == ["noop", "deadline"]*3
        end
      end

      it "should change existing values if present" do
        apply!(Puppet::Type.type(:kernel_parameter).new(
          :name     => "root",
          :ensure   => :present,
          :value    => ["test1", "test2"],
          :target   => target,
          :provider => "grub"
        ))

        aug_open(target, "Grub.lns") do |aug|
          aug.match("title/kernel/root").size.should == 6
          aug.match("title/kernel/root[.='/dev/VolGroup00/LogVol00']").size.should == 0
          aug.match("title/kernel/root").map {|p| aug.get(p)}.should == ["test1", "test2"]*3
        end
      end
    end
  end

  context "with broken file" do
    let(:tmptarget) { aug_fixture("broken") }
    let(:target) { tmptarget.path }

    it "should fail to load" do
      txn = apply(Puppet::Type.type(:kernel_parameter).new(
        :name     => "foo",
        :ensure   => :present,
        :target   => target,
        :provider => "grub"
      ))

      txn.any_failed?.should_not == nil
      @logs.first.level.should == :err
      @logs.first.message.include?(target).should == true
    end
  end
end
