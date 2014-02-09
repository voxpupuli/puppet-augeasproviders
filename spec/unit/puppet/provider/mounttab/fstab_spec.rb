#!/usr/bin/env rspec

require 'spec_helper'

type = Puppet::Type.type(:mounttab)
unless type
  raise Puppet::DevError, <<eos
Unable to autoload mounttab type from puppetlabs-mount_providers

Unable to load mounttab type - this should be provided by the external
puppetlabs-mount_providers module.

The puppetlabs_spec_helper library should fetch this when you run `rake spec`,
or you can run `rake spec_prep` to explicitly set up spec/fixtures/modules/.

Also possible is a Puppet autoloader bug.  spec/spec_helper.rb works around two
of these (in 2.7.20 and 3.0.x) by initialising Puppet[:libdir].

  Puppet[:modulepath] = #{Puppet[:modulepath].inspect}
  Puppet[:libdir] = #{Puppet[:libdir].inspect}

Ensure :libdir above refers to mount_providers/lib.

eos
end
provider_class = type.provider(:augeas)

describe provider_class do
  before :each do
    Facter.stubs(:value).with(:feature).returns(nil)
    Facter.stubs(:value).with(:osfamily).returns("RedHat")
    Facter.stubs(:value).with(:operatingsystem).returns("Fedora")
    FileTest.stubs(:exist?).returns false
    FileTest.stubs(:exist?).with('/etc/fstab').returns true
  end

  context "with empty file" do
    let(:tmptarget) { aug_fixture("empty") }
    let(:target) { tmptarget.path }

    it "should create simple new entry" do
      apply!(Puppet::Type.type(:mounttab).new(
        :name     => "/mnt",
        :device   => "/dev/myvg/mytest",
        :fstype   => "ext4",
        :options  => "defaults",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Fstab.lns") do |aug|
        aug.get("./1/spec").should == "/dev/myvg/mytest"
        aug.get("./1/file").should == "/mnt"
        aug.get("./1/vfstype").should == "ext4"
        aug.match("./1/opt").size.should == 1
        aug.get("./1/opt[1]").should == "defaults"
      end
    end

    it "should create new entry" do
      apply!(Puppet::Type.type(:mounttab).new(
        :name     => "/mnt",
        :device   => "/dev/myvg/mytest",
        :fstype   => "ext4",
        :options  => [ "nosuid", "uid=12345" ],
        :dump     => "1",
        :pass     => "2",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Fstab.lns") do |aug|
        aug.get("./1/spec").should == "/dev/myvg/mytest"
        aug.get("./1/file").should == "/mnt"
        aug.get("./1/vfstype").should == "ext4"
        aug.match("./1/opt").size.should == 2
        aug.get("./1/opt[1]").should == "nosuid"
        aug.get("./1/opt[2]").should == "uid"
        aug.get("./1/opt[2]/value").should == "12345"
        aug.get("./1/dump").should == "1"
        aug.get("./1/passno").should == "2"
      end
    end

    it "should create new entry without options" do
      apply!(Puppet::Type.type(:mounttab).new(
        :name     => "/mnt",
        :device   => "/dev/myvg/mytest",
        :fstype   => "ext4",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Fstab.lns") do |aug|
        aug.get("./1/spec").should == "/dev/myvg/mytest"
        aug.get("./1/file").should == "/mnt"
        aug.get("./1/vfstype").should == "ext4"
        aug.match("./1/opt").size.should == 1
        aug.get("./1/opt[1]").should == "defaults"
      end
    end
  end

  context "with full file" do
    let(:tmptarget) { aug_fixture("full") }
    let(:target) { tmptarget.path }

    it "should list instances" do
      provider_class.stubs(:target).returns(target)
      inst = provider_class.instances.map { |p|
        r = {}
        [:name,:ensure,:device,:blockdevice,:fstype,:options,:pass,:atboot,:dump].each { |pr| r[pr] = p.get(pr) }
        r
      }

      inst.size.should == 9
      inst[0].should == {:name=>"/", :ensure=>:present, :device=>"/dev/mapper/vgiridium-lvroot", :blockdevice=>:absent, :fstype=>"ext4", :options=>["noatime"], :pass=>:absent, :atboot=>:absent, :dump=>:absent}
      inst[1].should == {:name=>"/boot", :ensure=>:present, :device=>"UUID=23b3b5f4-d5b3-4661-ad41-caa970f3ca59", :blockdevice=>:absent, :fstype=>"ext4", :options=>["noatime"], :pass=>"2", :atboot=>:absent, :dump=>"1"}
      inst[2].should == {:name=>"/home", :ensure=>:present, :device=>"/dev/mapper/luks-10f63ee4-8296-434e-8de1-cde932e8a2e1", :blockdevice=>:absent, :fstype=>"ext4", :options=>["noatime"], :pass=>"2", :atboot=>:absent, :dump=>"1"}
      inst[3].should == {:name=>"/tmp", :ensure=>:present, :device=>"tmpfs", :blockdevice=>:absent, :fstype=>"tmpfs", :options=>["size=1024m"], :pass=>"0", :atboot=>:absent, :dump=>"0"}
    end

    it "should delete entries" do
      aug_open(target, "Fstab.lns") do |aug|
        aug.match("*[file = '/']").should_not == []
      end

      apply!(Puppet::Type.type(:mounttab).new(
        :name     => "/",
        :ensure   => "absent",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Fstab.lns") do |aug|
        aug.match("*[file = '/']").should == []
      end
    end

    it "should update device" do
      apply!(Puppet::Type.type(:mounttab).new(
        :name     => "/home",
        :device   => "/dev/myvg/mytest",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Fstab.lns") do |aug|
        aug.get("./3/file").should == "/home"
        aug.get("./3/spec").should == "/dev/myvg/mytest"

        aug.get("./3/vfstype").should == "ext4"
        aug.match("./3/opt").size.should == 1
        aug.get("./3/opt[1]").should == "noatime"
      end
    end

    it "should update device without changing dump or pass" do
      pending "issue #16122 against mounttab type as they're changing"

      apply!(Puppet::Type.type(:mounttab).new(
        :name     => "/home",
        :device   => "/dev/myvg/mytest",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Fstab.lns") do |aug|
        aug.get("./3/file").should == "/home"
        aug.get("./3/spec").should == "/dev/myvg/mytest"
        aug.get("./3/dump").should == "1"
        aug.get("./3/passno").should == "2"
      end
    end

    it "should update fstype" do
      apply!(Puppet::Type.type(:mounttab).new(
        :name     => "/home",
        :fstype   => "btrfs",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Fstab.lns") do |aug|
        aug.get("./3/file").should == "/home"
        aug.get("./3/vfstype").should == "btrfs"

        aug.get("./3/spec").should == "/dev/mapper/luks-10f63ee4-8296-434e-8de1-cde932e8a2e1"
        aug.match("./3/opt").size.should == 1
        aug.get("./3/opt[1]").should == "noatime"
      end
    end

    describe "when updating options" do
      it "should replace with one option" do
        apply!(Puppet::Type.type(:mounttab).new(
          :name     => "/home",
          :options  => "nosuid",
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Fstab.lns") do |aug|
          aug.get("./3/file").should == "/home"
          aug.match("./3/opt").size.should == 1
          aug.get("./3/opt[1]").should == "nosuid"

          aug.get("./3/spec").should == "/dev/mapper/luks-10f63ee4-8296-434e-8de1-cde932e8a2e1"
          aug.get("./3/vfstype").should == "ext4"
        end
      end

      it "should add multiple options" do
        apply!(Puppet::Type.type(:mounttab).new(
          :name     => "/home",
          :options  => ["nosuid", "nodev"],
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Fstab.lns") do |aug|
          aug.get("./3/file").should == "/home"
          aug.match("./3/opt").size.should == 2
          aug.get("./3/opt[1]").should == "nosuid"
          aug.get("./3/opt[2]").should == "nodev"
        end
      end

      it "should add various complex options" do
        apply!(Puppet::Type.type(:mounttab).new(
          :name     => "/home",
          :options  => ["nosuid", "uid=12345", 'rootcontext="system_u:object_r:tmpfs_t:s0"'],
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Fstab.lns") do |aug|
          aug.get("./3/file").should == "/home"
          aug.match("./3/opt").size.should == 3
          aug.get("./3/opt[1]").should == "nosuid"
          aug.get("./3/opt[2]").should == "uid"
          aug.get("./3/opt[2]/value").should == "12345"
          aug.get("./3/opt[3]").should == "rootcontext"
          aug.get("./3/opt[3]/value").should == '"system_u:object_r:tmpfs_t:s0"'
        end
      end

      it "should remove options" do
        apply!(Puppet::Type.type(:mounttab).new(
          :name     => "/home",
          :options  => [],
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Fstab.lns") do |aug|
          aug.get("./3/file").should == "/home"
          aug.match("./3/opt").size.should == 1
          aug.get("./3/opt[1]").should == "defaults"
        end
      end

      it "should leave options alone" do
        apply!(Puppet::Type.type(:mounttab).new(
          :name     => "/home",
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Fstab.lns") do |aug|
          aug.get("./3/file").should == "/home"
          aug.match("./3/opt").size.should == 1
          aug.get("./3/opt[1]").should == "noatime"
        end
      end
    end

    describe "when updating dump" do
      it "should add dump" do
        apply!(Puppet::Type.type(:mounttab).new(
          :name     => "/",
          :dump     => 1,
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Fstab.lns") do |aug|
          aug.get("./1/file").should == "/"
          aug.get("./1/dump").should == "1"
        end
      end

      it "should add options first, then dump" do
        apply!(Puppet::Type.type(:mounttab).new(
          :name     => "swap",
          :dump     => 1,
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Fstab.lns") do |aug|
          aug.get("./5/file").should == "swap"
          aug.match("./5/opt").size.should == 1
          aug.get("./5/opt[1]").should == "defaults"
          aug.get("./5/dump").should == "1"
        end
      end

      it "should change dump" do
        apply!(Puppet::Type.type(:mounttab).new(
          :name     => "/home",
          :dump     => 0,
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Fstab.lns") do |aug|
          aug.get("./3/file").should == "/home"
          aug.get("./3/dump").should == "0"
        end
      end
    end

    describe "when updating pass" do
      it "should add dump and pass" do
        apply!(Puppet::Type.type(:mounttab).new(
          :name     => "/",
          :pass     => 2,
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Fstab.lns") do |aug|
          aug.get("./1/file").should == "/"
          # dump will be missing, so it also has to be added
          aug.get("./1/dump").should == "0"
          aug.get("./1/passno").should == "2"
        end
      end

      it "should add options and dump first, then pass" do
        apply!(Puppet::Type.type(:mounttab).new(
          :name     => "swap",
          :pass     => 1,
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Fstab.lns") do |aug|
          aug.get("./5/file").should == "swap"
          aug.match("./5/opt").size.should == 1
          aug.get("./5/opt[1]").should == "defaults"
          aug.get("./5/dump").should == "0"
          aug.get("./5/passno").should == "1"
        end
      end

      it "should change pass" do
        apply!(Puppet::Type.type(:mounttab).new(
          :name     => "/home",
          :pass     => 1,
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Fstab.lns") do |aug|
          aug.get("./3/file").should == "/home"
          aug.get("./3/passno").should == "1"
        end
      end
    end
  end

  context "with broken file" do
    let(:tmptarget) { aug_fixture("broken") }
    let(:target) { tmptarget.path }

    it "should fail to load" do
      txn = apply(Puppet::Type.type(:mounttab).new(
        :name     => "/home",
        :device   => "LABEL=home",
        :target   => target,
        :provider => "augeas"
      ))

      txn.any_failed?.should_not == nil
      @logs.first.level.should == :err
      @logs.first.message.include?(target).should == true
    end
  end
end
