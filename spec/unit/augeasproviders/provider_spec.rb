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
        resource = { :name => 'foo' }
        subject.expects(:target).with(resource)
        subject.resource_path(resource).should == '/foo'
      end

      it "should call #target if a resource path block is set" do
        resource = { :name => 'foo' }
        subject.expects(:target).with(resource)
        subject.resource_path { '/files/test' }
        subject.resource_path(resource).should == '/files/test'
      end
    end

    describe "#readquote" do
      it "should return :double when value is double-quoted" do
        subject.readquote('"foo"').should == :double
      end

      it "should return :single when value is single-quoted" do
        subject.readquote("'foo'").should == :single
      end

      it "should return nil when value is not quoted" do
        subject.readquote("foo").should be_nil
      end

      it "should return nil when value is not properly quoted" do
        subject.readquote("'foo").should be_nil
        subject.readquote("'foo\"").should be_nil
        subject.readquote("\"foo").should be_nil
        subject.readquote("\"foo'").should be_nil
      end
    end

    describe "#quoteit" do
      it "should not do anything by default for alphanum values" do
        subject.quoteit('foo').should == 'foo'
      end

      it "should double-quote by default for values containing spaces or special characters" do
        subject.quoteit('foo bar').should == '"foo bar"'
        subject.quoteit('foo&bar').should == '"foo&bar"'
        subject.quoteit('foo;bar').should == '"foo;bar"'
        subject.quoteit('foo<bar').should == '"foo<bar"'
        subject.quoteit('foo>bar').should == '"foo>bar"'
        subject.quoteit('foo(bar').should == '"foo(bar"'
        subject.quoteit('foo)bar').should == '"foo)bar"'
        subject.quoteit('foo|bar').should == '"foo|bar"'
      end

      it "should call #readquote and use its value when oldvalue is passed" do
        subject.quoteit('foo', nil, "'bar'").should == "'foo'"
        subject.quoteit('foo', nil, '"bar"').should == '"foo"'
        subject.quoteit('foo', nil, 'bar').should == 'foo'
        subject.quoteit('foo bar', nil, "'bar'").should == "'foo bar'"
      end

      it "should double-quote special values when oldvalue is not quoted" do
        subject.quoteit('foo bar', nil, 'bar').should == '"foo bar"'
      end

      it "should use the :quoted parameter when present" do
        resource = { }
        resource.stubs(:parameters).returns([:quoted])

        resource[:quoted] = :single
        subject.quoteit('foo', resource).should == "'foo'"

        resource[:quoted] = :double
        subject.quoteit('foo', resource).should == '"foo"'

        resource[:quoted] = :auto
        subject.quoteit('foo', resource).should == 'foo'
        subject.quoteit('foo bar', resource).should == '"foo bar"'
      end
    end

    describe "#unquoteit" do
      it "should not do anything when value is not quoted" do
        subject.unquoteit('foo bar').should == 'foo bar'
      end

      it "should not do anything when value is badly quoted" do
        subject.unquoteit('"foo bar').should == '"foo bar'
        subject.unquoteit("'foo bar").should == "'foo bar"
        subject.unquoteit("'foo bar\"").should == "'foo bar\""
      end

      it "should return unquoted value" do
        subject.unquoteit('"foo bar"').should == 'foo bar'
        subject.unquoteit("'foo bar'").should == 'foo bar'
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
        subject.expects(:target).times(4).returns(thetarget)
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

      it "should call #setvars when given a block" do
        subject.expects(:setvars)
        subject.augopen(resource) { |aug,f| }
      end

      it "should not call #setvars when not given a block" do
        subject.expects(:setvars).never
        aug = subject.augopen(resource)
      end

      it "should call #augsave when given a block and autosave is true" do
        subject.expects(:augsave!)
        subject.augopen(resource, true) { |aug,f| }
      end

      it "should not call #augsave when not given a block" do
        subject.expects(:augsave!).never
        aug = subject.augopen(resource, true)
      end

      it "should not call #augsave when autosave is false" do
        subject.expects(:augsave!).never
        subject.augopen(resource) { |aug,f| }
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

    describe "#path_label" do
      it "should use Augeas#label when available" do
        subject.augopen(resource) do |aug,f|
          aug.expects(:respond_to?).with(:label).returns true
          aug.expects(:label).with('/files/foo[2]').returns 'foo'
          subject.path_label(aug, '/files/foo[2]').should == 'foo'
        end
      end

      it "should emulate Augeas#label when it is not available" do
        subject.augopen(resource) do |aug,f|
          aug.expects(:respond_to?).with(:label).returns false
          aug.expects(:label).with('/files/bar[4]').never
          subject.path_label(aug, '/files/bar[4]').should == 'bar'
        end
      end

      it "should emulate Augeas#label when no label is found in the tree" do
        subject.augopen(resource) do |aug,f|
          aug.expects(:respond_to?).with(:label).returns true
          aug.expects(:label).with('/files/baz[15]').returns nil
          subject.path_label(aug, '/files/baz[15]').should == 'baz'
        end
      end
    end

    describe "#setvars" do
      it "should call Augeas#defvar to set $target, $resource and /augeas/context when resource is passed" do
        subject.augopen(resource) do |aug,f|
          aug.expects(:set).with('/augeas/context', "/files#{thetarget}")
          aug.expects(:defvar).with('target', "/files#{thetarget}")
          subject.expects(:resource_path).with(resource).returns('/files/foo')
          aug.expects(:defvar).with('resource', '/files/foo')
          subject.setvars(aug, resource)
        end
      end

      it "should call Augeas#defvar to set $target but not $resource when no resource is passed" do
        subject.augopen(resource) do |aug,f|
          aug.expects(:defvar).with('target', '/files/foo')
          aug.expects(:defvar).never
          subject.setvars(aug)
        end
      end
    end
  end
end
