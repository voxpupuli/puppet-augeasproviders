#!/usr/bin/env rspec

require 'spec_helper'

describe "hosts provider" do
  context "with empty file" do
    let(:target) { aug_fixture("empty") }

    it "should create new entry" do
      apply(Puppet::Type.type(:host).new(
        :name     => "foo",
        :ip       => "192.168.1.1",
        :host_aliases => [ "foo-a", "foo-b" ],
        :comment  => "test",
        :target   => target,
        :provider => "augeas",
      ))

      aug_open(target, "Hosts.lns") do |aug|
        aug.set("/augeas/context", "/files#{target}/1")
        aug.get("ipaddr").should == "192.168.1.1"
        aug.get("canonical").should == "foo"
        aug.match("alias").size.should == 2
        aug.get("alias[1]").should == "foo-a"
        aug.get("alias[2]").should == "foo-b"
        aug.get("#comment").should == "test"
      end
    end
  end
end
