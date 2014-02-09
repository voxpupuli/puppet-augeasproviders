#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:mounttab).provider(:augeas)

describe provider_class do
  before :each do
    Facter.stubs(:value).with(:feature).returns(nil)
    Facter.stubs(:value).with(:osfamily).returns("Solaris")
    Facter.stubs(:value).with(:operatingsystem).returns("Solaris")
    FileTest.stubs(:exist?).returns false
    FileTest.stubs(:exist?).with('/etc/fstab').returns true
    FileTest.stubs(:exist?).with('/etc/vfstab').returns true
  end

  context "with empty vfstab file" do
    let(:tmptarget) { aug_fixture("empty") }
    let(:target) { tmptarget.path }

    it "should create simple new entry" do
      apply!(Puppet::Type.type(:mounttab).new(
        :name     => "/foo",
        :device   => "/dev/dsk/c1t1d1s1",
        :fstype   => "ufs",
        :atboot   => "yes",
        :target   => target,
        :provider => "augeas"
      ))

      augparse(target, "Vfstab.lns", '
        { "1"
          { "spec" = "/dev/dsk/c1t1d1s1" }
          { "fsck" = "/dev/rdsk/c1t1d1s1" }
          { "file" = "/foo" }
          { "vfstype" = "ufs" }
          { "atboot" = "yes" }
        }
      ')
    end

    it "should create new entry" do
      apply!(Puppet::Type.type(:mounttab).new(
        :name     => "/foo",
        :device   => "/dev/dsk/c1t1d1s1",
        :blockdevice => "/dev/foo/c1t1d1s1",
        :fstype   => "ufs",
        :pass     => "2",
        :atboot   => "yes",
        :options  => [ "nosuid", "nodev" ],
        :target   => target,
        :provider => "augeas"
      ))

      augparse(target, "Vfstab.lns", '
        { "1"
          { "spec" = "/dev/dsk/c1t1d1s1" }
          { "fsck" = "/dev/foo/c1t1d1s1" }
          { "file" = "/foo" }
          { "vfstype" = "ufs" }
          { "passno" = "2" }
          { "atboot" = "yes" }
          { "opt" = "nosuid" }
          { "opt" = "nodev" }
        }
      ')
    end
  end

  context "with full vfstab file" do
    let(:tmptarget) { aug_fixture("full") }
    let(:target) { tmptarget.path }

    it "should list instances" do
      provider_class.stubs(:target).returns(target)
      inst = provider_class.instances.map { |p|
        r = {}
        [:name,:ensure,:device,:blockdevice,:fstype,:options,:pass,:atboot,:dump].each { |pr| r[pr] = p.get(pr) }
        r
      }

      inst.size.should == 6
      inst[0].should == {:name=>"/dev/fd", :ensure=>:present, :device=>"fd", :blockdevice=>"-", :fstype=>"fd", :options=>"-", :pass=>"-", :atboot=>"no", :dump=>:absent}
      inst[1].should == {:name=>"/proc", :ensure=>:present, :device=>"/proc", :blockdevice=>"-", :fstype=>"proc", :options=>"-", :pass=>"-", :atboot=>"no", :dump=>:absent}
      inst[2].should == {:name=>"-", :ensure=>:present, :device=>"/dev/dsk/c0t0d0s1", :blockdevice=>"-", :fstype=>"swap", :options=>"-", :pass=>"-", :atboot=>"no", :dump=>:absent}
      inst[3].should == {:name=>"/", :ensure=>:present, :device=>"/dev/dsk/c0t0d0s0", :blockdevice=>"/dev/rdsk/c0t0d0s0", :fstype=>"ufs", :options=>"-", :pass=>"1", :atboot=>"no", :dump=>:absent}
      inst[5].should == {:name=>"/tmp", :ensure=>:present, :device=>"swap", :blockdevice=>"-", :fstype=>"tmpfs", :options=>["size=1024m"], :pass=>"-", :atboot=>"yes", :dump=>:absent}
    end

    it "should delete entries" do
      aug_open(target, "Vfstab.lns") do |aug|
        aug.match("*[file = '/']").should_not == []
      end

      apply!(Puppet::Type.type(:mounttab).new(
        :name     => "/",
        :ensure   => "absent",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Vfstab.lns") do |aug|
        aug.match("*[file = '/']").should == []
      end
    end

    it "should update device" do
      apply!(Puppet::Type.type(:mounttab).new(
        :name     => "/",
        :device   => "/dev/dsk/c1t1d1s1",
        :target   => target,
        :provider => "augeas"
      ))

      # fsck will get updated implicitly, due to the type
      # passno gets removed due to issue #16122 against mounttab
      # atboot will get changed, also #16122
      augparse_filter(target, "Vfstab.lns", "*[file='/']", '
        { "1"
          { "spec" = "/dev/dsk/c1t1d1s1" }
          { "fsck" = "/dev/rdsk/c1t1d1s1" }
          { "file" = "/" }
          { "vfstype" = "ufs" }
          { "atboot" = "yes" }
        }
      ')
    end

    it "should update fstype" do
      apply!(Puppet::Type.type(:mounttab).new(
        :name     => "/",
        :fstype   => "zfs",
        :target   => target,
        :provider => "augeas"
      ))

      # passno gets removed due to issue #16122 against mounttab
      # atboot will get changed, also #16122
      augparse_filter(target, "Vfstab.lns", "*[file='/']", '
        { "1"
          { "spec" = "/dev/dsk/c0t0d0s0" }
          { "fsck" = "/dev/rdsk/c0t0d0s0" }
          { "file" = "/" }
          { "vfstype" = "zfs" }
          { "atboot" = "yes" }
        }
      ')
    end

    describe "when updating options" do
      it "should replace with one option" do
        apply!(Puppet::Type.type(:mounttab).new(
          :name     => "/tmp",
          :options  => "nosuid",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Vfstab.lns", "*[file='/tmp']", '
          { "1"
            { "spec" = "swap" }
            { "file" = "/tmp" }
            { "vfstype" = "tmpfs" }
            { "atboot" = "yes" }
            { "opt" = "nosuid" }
          }
        ')
      end

      it "should add multiple options" do
        apply!(Puppet::Type.type(:mounttab).new(
          :name     => "/tmp",
          :options  => ["nosuid", "nodev"],
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Vfstab.lns", "*[file='/tmp']", '
          { "1"
            { "spec" = "swap" }
            { "file" = "/tmp" }
            { "vfstype" = "tmpfs" }
            { "atboot" = "yes" }
            { "opt" = "nosuid" }
            { "opt" = "nodev" }
          }
        ')
      end

      it "should remove options" do
        apply!(Puppet::Type.type(:mounttab).new(
          :name     => "/tmp",
          :options  => [],
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Vfstab.lns", "*[file='/tmp']", '
          { "1"
            { "spec" = "swap" }
            { "file" = "/tmp" }
            { "vfstype" = "tmpfs" }
            { "atboot" = "yes" }
          }
        ')
      end

      it "should leave options alone" do
        pending "issue #16122 against mounttab type as they're being removed"

        apply!(Puppet::Type.type(:mounttab).new(
          :name     => "/tmp",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Vfstab.lns", "*[file='/tmp']", '
          { "1"
            { "spec" = "swap" }
            { "file" = "/tmp" }
            { "vfstype" = "tmpfs" }
            { "atboot" = "yes" }
            { "opt" = "size"
              { "value" = "1024m" } }
          }
        ')
      end
    end

    describe "when updating blockdevice" do
      it "should add blockdevice" do
        apply!(Puppet::Type.type(:mounttab).new(
          :name     => "/tmp",
          :blockdevice => "/dev/tofsck",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Vfstab.lns", "*[file='/tmp']", '
          { "1"
            { "spec" = "swap" }
            { "fsck" = "/dev/tofsck" }
            { "file" = "/tmp" }
            { "vfstype" = "tmpfs" }
            { "atboot" = "yes" }
          }
        ')
      end

      it "should change blockdevice" do
        apply!(Puppet::Type.type(:mounttab).new(
          :name     => "/",
          :blockdevice => "/dev/foo/c0t0d0s0",
          :target   => target,
          :provider => "augeas"
        ))

        # passno gets removed due to issue #16122 against mounttab
        # atboot will get changed, also #16122
        augparse_filter(target, "Vfstab.lns", "*[file='/']", '
          { "1"
            { "spec" = "/dev/dsk/c0t0d0s0" }
            { "fsck" = "/dev/foo/c0t0d0s0" }
            { "file" = "/" }
            { "vfstype" = "ufs" }
            { "atboot" = "yes" }
          }
        ')
      end

      it "should remove blockdevice" do
        apply!(Puppet::Type.type(:mounttab).new(
          :name     => "/fsck",
          :blockdevice => "-",
          :target   => target,
          :provider => "augeas"
        ))

        # passno gets removed due to issue #16122 against mounttab
        # atboot will get changed, also #16122
        augparse_filter(target, "Vfstab.lns", "*[file='/fsck']", '
          { "1"
            { "spec" = "mydev" }
            { "file" = "/fsck" }
            { "vfstype" = "ufs" }
            { "atboot" = "yes" }
          }
        ')
      end
    end

    describe "when updating atboot" do
      it "should change atboot" do
        apply!(Puppet::Type.type(:mounttab).new(
          :name     => "/dev/fd",
          :atboot   => "yes",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Vfstab.lns", "*[file='/dev/fd']", '
          { "1"
            { "spec" = "fd" }
            { "file" = "/dev/fd" }
            { "vfstype" = "fd" }
            { "atboot" = "yes" }
          }
        ')
      end
    end

    describe "when updating pass" do
      it "should add pass" do
        apply!(Puppet::Type.type(:mounttab).new(
          :name     => "/dev/fd",
          :pass     => 2,
          :target   => target,
          :provider => "augeas"
        ))

        # atboot will get changed, also #16122
        augparse_filter(target, "Vfstab.lns", "*[file='/dev/fd']", '
          { "1"
            { "spec" = "fd" }
            { "file" = "/dev/fd" }
            { "vfstype" = "fd" }
            { "passno" = "2" }
            { "atboot" = "yes" }
          }
        ')
      end

      it "should change pass" do
        apply!(Puppet::Type.type(:mounttab).new(
          :name     => "/",
          :pass     => 7,
          :target   => target,
          :provider => "augeas"
        ))

        # atboot will get changed, also #16122
        augparse_filter(target, "Vfstab.lns", "*[file='/']", '
          { "1"
            { "spec" = "/dev/dsk/c0t0d0s0" }
            { "fsck" = "/dev/rdsk/c0t0d0s0" }
            { "file" = "/" }
            { "vfstype" = "ufs" }
            { "passno" = "7" }
            { "atboot" = "yes" }
          }
        ')
      end
    end
  end

  context "with broken vfstab file" do
    let(:tmptarget) { aug_fixture("broken") }
    let(:target) { tmptarget.path }

    it "should fail to load" do
      txn = apply(Puppet::Type.type(:mounttab).new(
        :name     => "/",
        :device   => "/dev/dsk/c0t0d1s0",
        :target   => target,
        :provider => "augeas"
      ))

      txn.any_failed?.should_not == nil
      @logs.first.level.should == :err
      @logs.first.message.include?(target).should == true
    end
  end
end
