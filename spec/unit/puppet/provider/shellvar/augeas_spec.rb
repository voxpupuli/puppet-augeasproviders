#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:shellvar).provider(:augeas)

describe provider_class do
  let(:unset_seq?) { subject.unset_seq? }

  context "with empty file" do
    let(:tmptarget) { aug_fixture("empty") }
    let(:target) { tmptarget.path }

    it "should create simple new entry" do
      apply!(Puppet::Type.type(:shellvar).new(
        :variable => "ENABLE",
        :value    => "true",
        :target   => target,
        :provider => "augeas"
      ))

      augparse(target, "Shellvars.lns", '
        { "ENABLE" = "true" }
      ')
    end

    it "should create new entry with multiple values as string" do
      apply!(Puppet::Type.type(:shellvar).new(
        :variable   => "PORTS",
        :value      => ["123", "456", 789],
        :array_type => "string",
        :target     => target,
        :provider   => "augeas"
      ))

      augparse(target, "Shellvars.lns", '
        { "PORTS" = "\"123 456 789\"" }
      ')
    end

    it "should create new entry with multiple values as array" do
      apply!(Puppet::Type.type(:shellvar).new(
        :variable   => "PORTS",
        :value      => ["123", "456", "789"],
        :array_type => "array",
        :target     => target,
        :provider   => "augeas"
      ))

      augparse(target, "Shellvars.lns", '
        { "PORTS"
          { "1" = "123" }
          { "2" = "456" }
          { "3" = "789" } }
      ')
    end

    it "should create new entry with comment" do
      apply!(Puppet::Type.type(:shellvar).new(
        :variable => "ENABLE",
        :value    => "true",
        :comment  => "test",
        :target   => target,
        :provider => "augeas"
      ))

      augparse(target, "Shellvars.lns", '
        { "#comment" = "ENABLE: test" }
        { "ENABLE" = "true" }
      ')
    end

    it "should create new entry as unset" do
      apply!(Puppet::Type.type(:shellvar).new(
        :ensure   => "unset",
        :variable => "ENABLE",
        :target   => target,
        :provider => "augeas"
      ))

      if unset_seq?
        augparse(target, "Shellvars.lns", '
          { "@unset" { "1" = "ENABLE" } }
        ')
      else
        augparse(target, "Shellvars.lns", '
          { "@unset" = "ENABLE" }
        ')
      end
    end

    it "should create new entry as unset with comment" do
      apply!(Puppet::Type.type(:shellvar).new(
        :ensure   => "unset",
        :variable => "ENABLE",
        :comment  => "test",
        :target   => target,
        :provider => "augeas"
      ))

      if unset_seq?
        augparse(target, "Shellvars.lns", '
          { "#comment" = "ENABLE: test" }
          { "@unset" { "1" = "ENABLE" } }
        ')
      else
        augparse(target, "Shellvars.lns", '
          { "#comment" = "ENABLE: test" }
          { "@unset" = "ENABLE" }
        ')
      end
    end

    it "should create new entry as exported" do
      apply!(Puppet::Type.type(:shellvar).new(
        :ensure   => "exported",
        :variable => "ENABLE",
        :value    => "true",
        :target   => target,
        :provider => "augeas"
      ))

      augparse(target, "Shellvars.lns", '
        { "ENABLE" = "true" { "export" } }
      ')
    end
  end

  context "with full file" do
    let(:tmptarget) { aug_fixture("full") }
    let(:target) { tmptarget.path }

    it "should create new entry next to commented out entry" do
      apply!(Puppet::Type.type(:shellvar).new(
        :variable => "SYNC_HWCLOCK",
        :value    => "yes",
        :target   => target,
        :provider => "augeas"
      ))

      if unset_seq?
        augparse_filter(target, "Shellvars.lns", '*[preceding-sibling::#comment[.=~regexp(".*sync hw clock.*")]]', '
          { "#comment" = "SYNC_HWCLOCK=no" }
          { "SYNC_HWCLOCK" = "yes" }
          { "EXAMPLE" = "foo" }
          { "@unset" { "1" = "EXAMPLE_U" } }
          { "EXAMPLE_E" = "baz" { "export" } }
          { "STR_LIST" = "\"foo bar baz\"" }
          { "LST_LIST"
            { "1" = "foo" }
            { "2" = "\"bar baz\"" }
            { "3" = "123" }
          }
        ')
      else
        augparse_filter(target, "Shellvars.lns", '*[preceding-sibling::#comment[.=~regexp(".*sync hw clock.*")]]', '
          { "#comment" = "SYNC_HWCLOCK=no" }
          { "SYNC_HWCLOCK" = "yes" }
          { "EXAMPLE" = "foo" }
          { "@unset" = "EXAMPLE_U" }
          { "EXAMPLE_E" = "baz" { "export" } }
          { "STR_LIST" = "\"foo bar baz\"" }
          { "LST_LIST"
            { "1" = "foo" }
            { "2" = "\"bar baz\"" }
            { "3" = "123" }
          }
        ')
      end
    end

    it "should replace comment with new entry" do
      apply!(Puppet::Type.type(:shellvar).new(
        :variable  => "SYNC_HWCLOCK",
        :value     => "yes",
        :uncomment => true,
        :target    => target,
        :provider  => "augeas"
      ))

      if unset_seq?
        augparse_filter(target, "Shellvars.lns", '*[preceding-sibling::#comment[.=~regexp(".*sync hw clock.*")]]', '
          { "SYNC_HWCLOCK" = "yes" }
          { "EXAMPLE" = "foo" }
          { "@unset" { "1" = "EXAMPLE_U" } }
          { "EXAMPLE_E" = "baz" { "export" } }
          { "STR_LIST" = "\"foo bar baz\"" }
          { "LST_LIST"
            { "1" = "foo" }
            { "2" = "\"bar baz\"" }
            { "3" = "123" }
          }
        ')
      else
        augparse_filter(target, "Shellvars.lns", '*[preceding-sibling::#comment[.=~regexp(".*sync hw clock.*")]]', '
          { "SYNC_HWCLOCK" = "yes" }
          { "EXAMPLE" = "foo" }
          { "@unset" = "EXAMPLE_U" }
          { "EXAMPLE_E" = "baz" { "export" } }
          { "STR_LIST" = "\"foo bar baz\"" }
          { "LST_LIST"
            { "1" = "foo" }
            { "2" = "\"bar baz\"" }
            { "3" = "123" }
          }
        ')
      end
    end

    it "should delete entries" do
      apply!(Puppet::Type.type(:shellvar).new(
        :variable => "RETRIES",
        :ensure   => "absent",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Shellvars.lns") do |aug|
        aug.match("RETRIES").should == []
        aug.match("#comment[. =~ regexp('RETRIES:.*')]").should == []
      end
    end

    it "should delete unset entries" do
      apply!(Puppet::Type.type(:shellvar).new(
        :variable => "EXAMPLE_U",
        :ensure   => "absent",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Shellvars.lns") do |aug|
        aug.match("EXAMPLE_U").should == []
        if unset_seq?
          aug.match("@unset[*='EXAMPLE_U']").should == []
        else
          aug.match("@unset[.='EXAMPLE_U']").should == []
        end
      end
    end

    describe "when updating value" do
      it "should change unquoted value" do
        apply!(Puppet::Type.type(:shellvar).new(
          :variable => "RETRIES",
          :value    => "1",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Shellvars.lns", "RETRIES", '
          { "RETRIES" = "1" }
        ')
      end

      it "should change quoted value" do
        apply!(Puppet::Type.type(:shellvar).new(
          :variable => "OPTIONS",
          :value    => "-p 3 -s",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Shellvars.lns", "OPTIONS", '
          { "OPTIONS" = "\"-p 3 -s\"" }
        ')
      end

      it "should leave single quotes as-is" do
        apply!(Puppet::Type.type(:shellvar).new(
          :variable => "OPTIONS_SINGLE",
          :value    => "3",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Shellvars.lns", "OPTIONS_SINGLE", '
          { "OPTIONS_SINGLE" = "\'3\'" }
        ')
      end

      it "should leave double quotes as-is" do
        apply!(Puppet::Type.type(:shellvar).new(
          :variable => "OPTIONS",
          :value    => "3",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Shellvars.lns", "OPTIONS", '
          { "OPTIONS" = "\"3\"" }
        ')
      end

      it "should automatically add quotes" do
        apply!(Puppet::Type.type(:shellvar).new(
          :variable => "RETRIES",
          :value    => "-p 3 -s",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Shellvars.lns", "RETRIES", '
          { "RETRIES" = "\"-p 3 -s\"" }
        ')
      end

      it "should add forced single quotes" do
        apply!(Puppet::Type.type(:shellvar).new(
          :variable => "RETRIES",
          :value    => "3",
          :quoted   => "single",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Shellvars.lns", "RETRIES", '
          { "RETRIES" = "\'3\'" }
        ')
      end

      it "should add forced double quotes" do
        apply!(Puppet::Type.type(:shellvar).new(
          :variable => "RETRIES",
          :value    => "3",
          :quoted   => "double",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Shellvars.lns", "RETRIES", '
          { "RETRIES" = "\"3\"" }
        ')
      end

      it "should error when removing necessary quotes" do
        txn = apply(Puppet::Type.type(:shellvar).new(
          :variable => "OPTIONS",
          :value    => "-p 3",
          :quoted   => "false",
          :target   => target,
          :provider => "augeas"
        ))

        txn.any_failed?.should_not == nil
        logs_num = Puppet::Util::Package.versioncmp(Puppet.version, '3.4.0') >= 0 ? 1 : 0
        @logs[logs_num].level.should == :err
        @logs[logs_num].message.include?('Failed to save').should == true
      end

      it "should update string array value as auto string" do
        apply!(Puppet::Type.type(:shellvar).new(
          :variable   => "STR_LIST",
          :value      => ["foo", "baz"],
          :array_type => 'auto',
          :target     => target,
          :provider   => "augeas"
        ))

        augparse_filter(target, "Shellvars.lns", "STR_LIST", '
          { "STR_LIST" = "\"foo baz\"" }
        ')
      end

      it "should update string array value as array" do
        apply!(Puppet::Type.type(:shellvar).new(
          :variable   => "STR_LIST",
          :value      => ["foo", "baz"],
          :array_type => 'array',
          :target     => target,
          :provider   => "augeas"
        ))

        augparse_filter(target, "Shellvars.lns", "STR_LIST", '
          { "STR_LIST"
            { "1" = "foo" }
            { "2" = "baz" } }
        ')
      end

      it "should update array array value as auto array" do
        apply!(Puppet::Type.type(:shellvar).new(
          :variable   => "LST_LIST",
          :value      => ["foo", "baz"],
          :array_type => 'auto',
          :target     => target,
          :provider   => "augeas"
        ))

        augparse_filter(target, "Shellvars.lns", "LST_LIST", '
          { "LST_LIST"
            { "1" = "foo" }
            { "2" = "baz" } }
        ')
      end

      it "should update array array value as string" do
        apply!(Puppet::Type.type(:shellvar).new(
          :variable   => "LST_LIST",
          :value      => ["foo", "baz"],
          :array_type => 'string',
          :target     => target,
          :provider   => "augeas"
        ))

        augparse_filter(target, "Shellvars.lns", "LST_LIST", '
          { "LST_LIST" = "\"foo baz\"" }
        ')
      end
    end

    describe "when using array_append" do
      it "should not remove existing values" do
        apply!(Puppet::Type.type(:shellvar).new(
          :variable     => "STR_LIST",
          :value        => ["foo", "fooz"],
          :array_append => true,
          :target       => target,
          :provider     => "augeas"
        ))

        augparse_filter(target, "Shellvars.lns", "STR_LIST", '
          { "STR_LIST" = "\"foo bar baz fooz\"" }
        ')
      end
    end

    describe "when updating comment" do
      it "should add comment" do
        apply!(Puppet::Type.type(:shellvar).new(
          :variable => "OPTIONS",
          :comment  => "test comment",
          :target   => target,
          :provider => "augeas"
        ))

        augparse_filter(target, "Shellvars.lns", '*[following-sibling::OPTIONS]', '
            { "#comment" = "OPTIONS: test comment" }
        ')
      end

      it "should change comment" do
        apply!(Puppet::Type.type(:shellvar).new(
          :variable => "RETRIES",
          :comment  => "Never gonna give you up",
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Shellvars.lns") do |aug|
          aug.match("#comment[. = 'retry setting']").should_not == []
          aug.match("#comment[. = 'RETRIES: Never gonna give you up']").should_not == []
        end
      end

      it "should remove comment" do
        apply!(Puppet::Type.type(:shellvar).new(
          :variable => "RETRIES",
          :comment  => "",
          :target   => target,
          :provider => "augeas"
        ))

        aug_open(target, "Shellvars.lns") do |aug|
          aug.match("#comment[. =~ regexp('RETRIES:.*')]").should == []
          aug.match("#comment[. = 'retry setting']").should_not == []
        end
      end
    end

    it "should set value as unset" do
      apply!(Puppet::Type.type(:shellvar).new(
        :ensure   => "unset",
        :variable => "EXAMPLE",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Shellvars.lns") do |aug|
        aug.match("EXAMPLE").should == []
        aug.match("@unset").size.should == 2
      end
    end

    it "should set value as unset from exported" do
      apply!(Puppet::Type.type(:shellvar).new(
        :ensure   => "unset",
        :variable => "EXAMPLE_E",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Shellvars.lns") do |aug|
        aug.match("EXAMPLE_E").should == []
        aug.match("@unset").size.should == 2
      end
    end

    it "should set value as exported" do
      apply!(Puppet::Type.type(:shellvar).new(
        :ensure   => "exported",
        :variable => "EXAMPLE",
        :value    => "foo",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Shellvars.lns") do |aug|
        aug.match("EXAMPLE/export").should_not == []
      end
    end

    it "should set value as exported from unset" do
      apply!(Puppet::Type.type(:shellvar).new(
        :ensure   => "exported",
        :variable => "EXAMPLE_U",
        :value    => "foo",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Shellvars.lns") do |aug|
        if unset_seq?
          aug.match("@unset[*='EXAMPLE_U']").should == []
        else
          aug.match("@unset[.='EXAMPLE_U']").should == []
        end
        aug.match("EXAMPLE_U/export").should_not == []
      end
    end

    it "should un-unset value" do
      apply!(Puppet::Type.type(:shellvar).new(
        :ensure   => "present",
        :variable => "EXAMPLE_U",
        :value    => "foo",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Shellvars.lns") do |aug|
        if unset_seq?
          aug.match("@unset[*='EXAMPLE_U']").should == []
        else
          aug.match("@unset[.='EXAMPLE_U']").should == []
        end
        aug.match("EXAMPLE_U/export").should == []
        aug.get("EXAMPLE_U").should == 'foo'
      end
    end

    it "should un-export value" do
      apply!(Puppet::Type.type(:shellvar).new(
        :ensure   => "present",
        :variable => "EXAMPLE_E",
        :value    => "foo",
        :target   => target,
        :provider => "augeas"
      ))

      aug_open(target, "Shellvars.lns") do |aug|
        aug.match("EXAMPLE_E/export").should == []
        aug.get("EXAMPLE_E").should == 'foo'
      end
    end
  end

  context "with broken file" do
    let(:tmptarget) { aug_fixture("broken") }
    let(:target) { tmptarget.path }

    it "should fail to load" do
      txn = apply(Puppet::Type.type(:shellvar).new(
        :variable => "RETRIES",
        :value    => "1",
        :target   => target,
        :provider => "augeas"
      ))

      txn.any_failed?.should_not == nil
      @logs.first.level.should == :err
      @logs.first.message.include?(target).should == true
    end
  end
end
