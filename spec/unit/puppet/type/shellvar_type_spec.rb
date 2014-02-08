#!/usr/bin/env rspec

require 'spec_helper'

describe Puppet::Type.type(:shellvar) do
  describe "when setting quoted" do
    it "should have a default of auto" do
      resource = Puppet::Type.type(:shellvar).new :variable => "foo"
      resource[:quoted].should == :auto
    end

    it "should convert true to auto" do
      resource = Puppet::Type.type(:shellvar).new :variable => "foo", :quoted => :true
      resource[:quoted].should == :auto
    end

    it "should convert false to none" do
      resource = Puppet::Type.type(:shellvar).new :variable => "foo", :quoted => :false
      resource[:quoted].should == :none
    end
  end
end
