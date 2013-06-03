#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:shellvar).provider(:augeas)

describe provider_class do
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

      augparse_filter(target, "Shellvars.lns", '*[preceding-sibling::#comment[.=~regexp(".*sync hw clock.*")]]', '
        { "#comment" = "SYNC_HWCLOCK=no" }
        { "SYNC_HWCLOCK" = "yes" }
        { "EXAMPLE" = "foo" }
        { "STR_LIST" = "\"foo bar baz\"" }
        { "LST_LIST"
          { "1" = "foo" }
          { "2" = "\"bar baz\"" }
          { "3" = "123" }
        }
      ')
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
        @logs.first.level.should == :err
        @logs.first.message.include?(target).should == true
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

    describe "when updating comment" do
      it "should add comment" do
        apply!(Puppet::Type.type(:shellvar).new(
          :variable => "OPTIONS",
          :comment  => "test comment",
          :target   => target,
          :provider => "augeas"
        ))

        augparse(target, "Shellvars.lns", '
          { "#comment" = "Options for ntpdate" }
          { "#comment" = "OPTIONS: test comment" }
          { "OPTIONS" = "\"-p 2\"" }
          { "OPTIONS_SINGLE" = "\'-p 2\'" }
          { "#comment" = "retry setting" }
          { "#comment" = "RETRIES: Number of retries before giving up" }
          { "RETRIES" = "2" }
          { "#comment" = "Set to \'yes\' to sync hw clock after successful ntpdate" }
          { "#comment" = "SYNC_HWCLOCK=no" }
          { "EXAMPLE" = "foo" }
          { "STR_LIST" = "\"foo bar baz\"" }
          { "LST_LIST"
            { "1" = "foo" }
            { "2" = "\"bar baz\"" }
            { "3" = "123" }
          }
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
