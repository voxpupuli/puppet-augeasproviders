#!/usr/bin/env rspec

require 'spec_helper'

describe Puppet::Type.type(:shellvar) do
  context "when setting quoted" do
    it "should have a default of auto" do
      resource = Puppet::Type.type(:shellvar).new :name => "foo"
      resource[:quoted].should == :auto
    end

    it "should convert true to auto" do
      resource = Puppet::Type.type(:shellvar).new :name => "foo", :quoted => :true
      resource[:quoted].should == :auto
    end

    it "should convert false to none" do
      resource = Puppet::Type.type(:shellvar).new :name => "foo", :quoted => :false
      resource[:quoted].should == :none
    end
  end

  context "when using composite namevar" do
    it "should have a variable and target" do
      resource = Puppet::Type.type(:shellvar).new :name => "foo in /tmp/bar"
      resource[:variable].should == 'foo'
      resource[:target].should == '/tmp/bar'
    end
  end
end
