#!/usr/bin/env rspec

require 'spec_helper'
require 'augeasproviders/provider'

describe AugeasProviders::Provider do
  context "empty provider" do
    class Empty
      include AugeasProviders::Provider
      attr_accessor :resource
    end
    subject { Empty }

    describe "#lens" do
      it "should fail as default lens isn't set" do
        subject.expects(:fail).with('Lens is not provided').raises
        expect { subject.lens }.to raise_error
      end
    end

    describe "#target" do
      it "should fail if no default or resource file" do
        subject.expects(:fail).with('No target file given').raises
        expect { subject.target }.to raise_error
      end

      it "should return resource file if set" do
        subject.target(:target => '/foo').should == '/foo'
      end

      it "should strip trailing / from resource file" do
        subject.target(:target => '/foo/').should == '/foo'
      end
    end

    describe "#resource_path" do
      it "should call #target if no resource path block set" do
        subject.expects(:target).with('foo')
        subject.resource_path('foo')
      end
    end
  end

  context "working provider" do
    class Test
      include AugeasProviders::Provider
      lens { 'Hosts.lns' }
      default_file { '/foo' }
      resource_path { |r, p| r[:test] }
      attr_accessor :resource
    end

    subject { Test }
    let(:tmptarget) { aug_fixture("full") }
    let(:thetarget) { tmptarget.path }
    let(:resource) { {:target => thetarget} }

    # Class methods
    describe "#lens" do
      it "should allow retrieval of the set lens" do
        subject.lens.should == 'Hosts.lns'
      end
    end

    describe "#target" do
      it "should allow retrieval of the set default file" do
        subject.target.should == '/foo'
      end
    end

    describe "#resource_path" do
      it "should call block to get the resource path" do
        subject.resource_path(:test => 'bar').should == 'bar'
      end
    end

    describe "#augopen" do
      it "should get the path from #target" do
        subject.expects(:target).times(3).returns(thetarget)
        subject.augopen(resource) do |a,f|
          f.should == "/files#{thetarget}"
        end
      end

      it "should call Augeas#close when given a block" do
        subject.augopen(resource) do |aug,f|
          aug.expects(:close)
        end
      end

      it "should not call Augeas#close when not given a block" do
        Augeas.any_instance.expects(:close).never
        aug = subject.augopen(resource)
      end

      context "with broken file" do
        let(:tmptarget) { aug_fixture("broken") }

        it "should fail if the file fails to load" do
          subject.expects(:fail).with(regexp_matches(/Augeas didn't load #{Regexp.escape(thetarget)} with Hosts.lns from .*: Iterated lens matched less than it should/)).raises
          expect { subject.augopen(resource) {} }.to raise_error
        end
      end
    end

    describe "#augsave" do
      it "should print /augeas//error on save" do
        subject.augopen(resource) do |aug,f|
          # Prepare an invalid save
          aug.rm("/files#{thetarget}/*/ipaddr").should_not == 0
          lambda { subject.augsave!(aug) }.should raise_error Augeas::Error, /message = Failed to match/
        end
      end
    end
  end
end
