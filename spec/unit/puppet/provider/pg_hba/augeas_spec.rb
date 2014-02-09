#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:pg_hba).provider(:augeas)

RSpec.configure do |c|
  c.filter_run_excluding :composite => false
end

if Puppet.version =~ /^0\./
  composite_supported = false
else
  composite_supported = true
end

describe provider_class do
  context "when composite namevars are supported", :composite => composite_supported do
    context "with no existing file" do
      before(:all) { @tmpdir = Dir.mktmpdir }
      let(:target) { File.join(@tmpdir, "new_file") }
      after(:all) { FileUtils.remove_entry_secure @tmpdir }

      it "should create simple new local entry" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "local to all on all",
          :method   => "md5",
          :target   => target,
          :provider => "augeas"
        ))

        augparse(target, "Pg_hba.lns", '
           { "1"
             { "type" = "local" }
             { "database" = "all" }
             { "user" = "all" }
             { "method" = "md5" }
           }
        ')
      end
    end

    context "with empty file" do
      let(:tmptarget) { aug_fixture("empty") }
      let(:target) { tmptarget.path }

      it "should create simple new local entry" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "local to all on all",
          :method   => "md5",
          :target   => target,
          :provider => "augeas"
        ))

        augparse(target, "Pg_hba.lns", '
           { "1"
             { "type" = "local" }
             { "database" = "all" }
             { "user" = "all" }
             { "method" = "md5" }
           }
        ')
      end

      context 'when specifying target in namevar' do
        it "should create simple new local entry" do
          apply!(Puppet::Type.type(:pg_hba).new(
            :name     => "local to all on all in #{target}",
            :method   => "md5",
            :provider => "augeas"
          ))

          augparse(target, "Pg_hba.lns", '
             { "1"
               { "type" = "local" }
               { "database" = "all" }
               { "user" = "all" }
               { "method" = "md5" }
             }
          ')
        end
      end

      it "should create simple new local entry with random namevar and using default" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "A local entry",
          :method   => "md5",
          :target   => target,
          :provider => "augeas"
        ))

        augparse(target, "Pg_hba.lns", '
           { "1"
             { "type" = "local" }
             { "database" = "all" }
             { "user" = "all" }
             { "method" = "md5" }
           }
        ')
      end

      it "should create simple new local entry with options" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "local to all on all",
          :method   => "ident",
          :options  => {
            'sameuser'   => :undef,
            'krb_realm'  => 'EXAMPLE.COM',
            'ldapsuffix' => ',ou=people,dc=example,dc=com',
            },
          :target   => target,
          :provider => "augeas"
        ))

        # Options can be in various orders (hash)
        aug_open(target, "Pg_hba.lns") do |aug|
          aug.match("*/method/option[.='sameuser']").size.should == 1
          aug.match("*/method/option[.='krb_realm' and value='EXAMPLE.COM']").size.should == 1
          aug.match("*/method/option[.='ldapsuffix' and value=',ou=people,dc=example,dc=com']").size.should == 1
        end
      end

      it "should create simple new host entry" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "host to all on all from 1.2.3.4",
          :method   => "md5",
          :target   => target,
          :provider => "augeas"
        ))

        augparse(target, "Pg_hba.lns", '
           { "1"
             { "type" = "host" }
             { "database" = "all" }
             { "user" = "all" }
             { "address" = "1.2.3.4" }
             { "method" = "md5" }
           }
        ')
      end

      it "should create new local entry with multiple users and databases" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "local to +titi,@toto on db1,db2",
          :method   => "md5",
          :target   => target,
          :provider => "augeas"
        ))

        augparse(target, "Pg_hba.lns", '
           { "1"
             { "type" = "local" }
             { "database" = "db1" }
             { "database" = "db2" }
             { "user" = "+titi" }
             { "user" = "@toto" }
             { "method" = "md5" }
           }
        ')
      end

      it "should create new local entry with multiple users and databases using personalized namevar" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "+titi and @toto on db1 and db2",
          :user     => ['+titi', '@toto'],
          :database => ['db1', 'db2'],
          :method   => "md5",
          :target   => target,
          :provider => "augeas"
        ))

        augparse(target, "Pg_hba.lns", '
           { "1"
             { "type" = "local" }
             { "database" = "db1" }
             { "database" = "db2" }
             { "user" = "+titi" }
             { "user" = "@toto" }
             { "method" = "md5" }
           }
        ')
      end
    end

    context "with full file" do
      let(:tmptarget) { aug_fixture("full") }
      let(:target) { tmptarget.path }

      it "should create new entry" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "local to all on mydb",
          :method   => "md5",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Pg_hba.lns", "*[database='mydb']", '
           { "1"
             { "type" = "local" }
             { "database" = "mydb" }
             { "user" = "all" }
             { "method" = "md5" }
           }
        ')
      end

      it "should create new entry after first entry" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "local to all on mydb",
          :position => "after *[type][1]",
          :method   => "md5",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Pg_hba.lns", "./2", '
           { "1"
             { "type" = "local" }
             { "database" = "mydb" }
             { "user" = "all" }
             { "method" = "md5" }
           }
        ')
      end

      it "should create new entry before first entry" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "local to all on mydb",
          :position => "before *[type][1]",
          :method   => "md5",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Pg_hba.lns", "./1", '
           { "1"
             { "type" = "local" }
             { "database" = "mydb" }
             { "user" = "all" }
             { "method" = "md5" }
           }
        ')
      end

      it "should create new entry before first entry using shortcut" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "local to all on mydb",
          :position => "before first entry",
          :method   => "md5",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Pg_hba.lns", "./1", '
           { "1"
             { "type" = "local" }
             { "database" = "mydb" }
             { "user" = "all" }
             { "method" = "md5" }
           }
        ')
      end

      it "should create new entry before last entry using shortcut" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "local to all on mydb",
          :position => "before last entry",
          :method   => "md5",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Pg_hba.lns", "./16", '
           { "1"
             { "type" = "local" }
             { "database" = "mydb" }
             { "user" = "all" }
             { "method" = "md5" }
           }
        ')
      end

      it "should create new entry after first host using shortcut" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "local to all on mydb",
          :position => "after first host",
          :method   => "md5",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Pg_hba.lns", "./3", '
           { "1"
             { "type" = "local" }
             { "database" = "mydb" }
             { "user" = "all" }
             { "method" = "md5" }
           }
        ')
      end

      it "should create new entry before last anyhost using shortcut" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "local to all on mydb",
          :position => "before last anyhost",
          :method   => "md5",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Pg_hba.lns", "./11", '
           { "1"
             { "type" = "local" }
             { "database" = "mydb" }
             { "user" = "all" }
             { "method" = "md5" }
           }
        ')
      end

      it "should delete local entry" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "local to all on all",
          :ensure   => "absent",
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Pg_hba.lns") do |aug|
          aug.match("*[type='local' and user='all' and database='all']").should == []
        end
      end

      it "should update value of local entry" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "local to all on all",
          :method   => "bar",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Pg_hba.lns", "*[type='local' and user='all' and database='all']", '
           { "1"
             { "type" = "local" }
             { "database" = "all" }
             { "user" = "all" }
             { "method" = "bar" }
           }
        ')
      end

      it "should update value of local entry with options" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "local to all on all",
          :method   => "ident",
          :options  => {
            'sameuser' => :undef,
            },
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Pg_hba.lns", "*[type='local' and user='all' and database='all']", '
           { "1"
             { "type" = "local" }
             { "database" = "all" }
             { "user" = "all" }
             { "method" = "ident"
               { "option" = "sameuser" } }
           }
        ')
      end

      it "should move first entry after last entry" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "local to all on all",
          :ensure   => "positioned",
          :method   => "trust",
          :position => "after last entry",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Pg_hba.lns", "./16", '
           { "1"
             { "type" = "local" }
             { "database" = "all" }
             { "user" = "all" }
             { "method" = "trust" }
           }
        ')
      end

      it "should move entry before first host" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "local to sameuser on all",
          :ensure   => "positioned",
          :method   => "md5",
          :position => "before first host",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Pg_hba.lns", "./2", '
           { "1"
             { "type" = "local" }
             { "database" = "all" }
             { "user" = "sameuser" }
             { "method" = "md5" }
           }
        ')
      end

      it "should create simple new host entry" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "host to all on all from 1.2.3.4",
          :method   => "md5",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Pg_hba.lns", "*[type='host' and user='all' and database='all' and address='1.2.3.4']", '
           { "1"
             { "type" = "host" }
             { "database" = "all" }
             { "user" = "all" }
             { "address" = "1.2.3.4" }
             { "method" = "md5" }
           }
        ')
      end

      it "should delete host entry" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "host to all on all from 127.0.0.1/32",
          :ensure   => "absent",
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Pg_hba.lns") do |aug|
          aug.match("*[type='host' and user='all' and database='all' and address='127.0.0.1/32']").should == []
        end
      end

      it "should update value of host entry" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "host to all on all from 127.0.0.1/32",
          :method   => "md5",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Pg_hba.lns", "*[type='host' and user='all' and database='all' and address='127.0.0.1/32']", '
           { "1"
             { "type" = "host" }
             { "database" = "all" }
             { "user" = "all" }
             { "address" = "127.0.0.1/32" }
             { "method" = "md5" }
           }
        ')
      end

      it "should update value of host entry with options" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "host to all on all from 192.168.0.0/16",
          :method   => "ident",
          :options  => {
            'sameuser' => :undef,
            'map'      => 'omicron',
            },
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Pg_hba.lns") do |aug|
          aug.match("*[address='192.168.0.0/16']/method/option[.='sameuser']").size.should == 1
          aug.match("*[address='192.168.0.0/16']/method/option[.='map' and value='omicron']").size.should == 1
        end
      end

      it "should update value of host entry with options removed" do
        apply!(Puppet::Type.type(:pg_hba).new(
          :name     => "host to all on all from 192.168.0.0/16",
          :method   => "ident",
          :options  => {
            'sameuser' => :undef,
            },
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Pg_hba.lns") do |aug|
          aug.match("*[address='192.168.0.0/16']/method/option[.='sameuser']").size.should == 1
          aug.match("*[address='192.168.0.0/16']/method/option[.='map' and value='omicron']").size.should == 0
        end
      end
    end

    context "with broken file" do
      let(:tmptarget) { aug_fixture("broken") }
      let(:target) { tmptarget.path }

      it "should fail to load" do
        txn = apply(Puppet::Type.type(:pg_hba).new(
          :name     => "local to all on all",
          :method   => "md5",
          :target   => target,
          :provider => "augeas"
        ))

        txn.any_failed?.should_not == nil
        @logs.first.level.should == :err
        @logs.first.message.include?(target).should == true
      end
    end
  end
end
