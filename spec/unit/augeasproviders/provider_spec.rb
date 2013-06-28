#!/usr/bin/env rspec

require 'spec_helper'
require 'augeasproviders/provider'

describe AugeasProviders::Provider do
  class Test
    include AugeasProviders::Provider
    lens { 'Hosts.lns' }
    default_file { '/foo' }
    attr_accessor :resource
  end

  let(:tmptarget) { aug_fixture("full") }
  let(:thetarget) { tmptarget.path }
  let(:provider) { Test.new }

  it "should print /augeas//error on save" do
    # Prepare an invalid save
    provider.resource = {:target => thetarget}

    aug = provider.augopen
    aug.rm("/files#{thetarget}/*/ipaddr").should_not == 0

    lambda { provider.augsave!(aug) }.should raise_error Augeas::Error, /message = Failed to match/
  end
end
