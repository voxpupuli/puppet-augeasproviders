#!/usr/bin/env rspec

require 'spec_helper'

describe "hosts provider" do
  context "with empty file" do
    let(:target) { aug_fixture("empty") }

    it "should create new entry" do
      apply(Puppet::Type.type(:host).new(
        :name     => "foo",
        :ip       => "192.168.1.1",
        :comment  => "test",
        :target   => target,
        :provider => "augeas",
      ))

      aug_open(target, "Hosts.lns") do |aug|
        aug.set("/augeas/context", "/files#{target}/1")
        aug.get("canonical").should == "foo"
        aug.get("ipaddr").should == "192.168.1.1"
        aug.get("#comment").should == "test"
        aug.match("alias").should == []
      end
    end
  end
end
