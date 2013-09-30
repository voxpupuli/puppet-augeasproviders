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

    describe "#attr_aug_reader" do
      it "should create a class method" do
        subject.attr_aug_reader(:foo, {})
        subject.method_defined?('attr_aug_reader_foo').should be_true
      end
    end

    describe "#attr_aug_writer" do
      it "should create a class method" do
        subject.attr_aug_writer(:foo, {})
        subject.method_defined?('attr_aug_writer_foo').should be_true
      end
    end

    describe "#attr_aug_accessor" do
      it "should call #attr_aug_reader and #attr_aug_writer" do
        name = :foo
        opts = { :bar => 'baz' }
        subject.expects(:attr_aug_reader).with(name, opts)
        subject.expects(:attr_aug_writer).with(name, opts)
        subject.attr_aug_accessor(name, opts)
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

    describe "#loadpath" do
      it "should return AugeasProviders::Provider.loadpath" do
        subject.send(:loadpath).should == AugeasProviders::Provider.loadpath
      end

      it "should add libdir/augeas/lenses/ to the loadpath if it exists" do
        plugindir = File.join(Puppet[:libdir], 'augeas', 'lenses')
        File.expects(:exists?).with(plugindir).returns(true)
        subject.send(:loadpath).should == "#{AugeasProviders::Provider.loadpath}:#{plugindir}"
      end
    end

    describe "#augopen" do
      before do
        subject.expects(:augsave!).never
      end

      it "should call Augeas#close when given a block" do
        subject.augopen(resource) do |aug|
          aug.expects(:close)
        end
      end

      it "should not call Augeas#close when not given a block" do
        Augeas.any_instance.expects(:close).never
        aug = subject.augopen(resource)
      end

      it "should call #setvars when given a block" do
        subject.expects(:setvars)
        subject.augopen(resource) { |aug| }
      end

      it "should not call #setvars when not given a block" do
        subject.expects(:setvars).never
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

    describe "#augopen!" do
      it "should call Augeas#close when given a block" do
        subject.augopen!(resource) do |aug|
          aug.expects(:close)
        end
      end

      it "should not call Augeas#close when not given a block" do
        Augeas.any_instance.expects(:close).never
        aug = subject.augopen!(resource)
      end

      it "should call #setvars when given a block" do
        subject.expects(:setvars)
        subject.augopen!(resource) { |aug| }
      end

      it "should not call #setvars when not given a block" do
        subject.expects(:setvars).never
        aug = subject.augopen!(resource)
      end

      it "should call #augsave when given a block" do
        subject.expects(:augsave!)
        subject.augopen!(resource) { |aug| }
      end

      it "should not call #augsave when not given a block" do
        subject.expects(:augsave!).never
        aug = subject.augopen!(resource)
      end

      context "with broken file" do
        let(:tmptarget) { aug_fixture("broken") }

        it "should fail if the file fails to load" do
          subject.expects(:fail).with(regexp_matches(/Augeas didn't load #{Regexp.escape(thetarget)} with Hosts.lns from .*: Iterated lens matched less than it should/)).raises
          expect { subject.augopen!(resource) {} }.to raise_error
        end
      end
    end

    describe "#augsave" do
      it "should print /augeas//error on save" do
        subject.augopen(resource) do |aug|
          # Prepare an invalid save
          aug.rm("/files#{thetarget}/*/ipaddr").should_not == 0
          lambda { subject.augsave!(aug) }.should raise_error Augeas::Error, /message = Failed to match/
        end
      end
    end

    describe "#path_label" do
      it "should use Augeas#label when available" do
        subject.augopen(resource) do |aug|
          aug.expects(:respond_to?).with(:label).returns true
          aug.expects(:label).with('/files/foo[2]').returns 'foo'
          subject.path_label(aug, '/files/foo[2]').should == 'foo'
        end
      end

      it "should emulate Augeas#label when it is not available" do
        subject.augopen(resource) do |aug|
          aug.expects(:respond_to?).with(:label).returns false
          aug.expects(:label).with('/files/bar[4]').never
          subject.path_label(aug, '/files/bar[4]').should == 'bar'
        end
      end

      it "should emulate Augeas#label when no label is found in the tree" do
        subject.augopen(resource) do |aug|
          aug.expects(:respond_to?).with(:label).returns true
          aug.expects(:label).with('/files/baz[15]').returns nil
          subject.path_label(aug, '/files/baz[15]').should == 'baz'
        end
      end
    end

    describe "#setvars" do
      it "should call Augeas#defnode to set $target, Augeas#defvar to set $resource and Augeas#set to set /augeas/context when resource is passed" do
        subject.augopen(resource) do |aug|
          aug.expects(:set).with('/augeas/context', "/files#{thetarget}")
          aug.expects(:defnode).with('target', "/files#{thetarget}", nil)
          subject.expects(:resource_path).with(resource).returns('/files/foo')
          aug.expects(:defvar).with('resource', '/files/foo')
          subject.setvars(aug, resource)
        end
      end

      it "should call Augeas#defnode to set $target but not $resource when no resource is passed" do
        subject.augopen(resource) do |aug|
          aug.expects(:defnode).with('target', '/files/foo', nil)
          aug.expects(:defvar).never
          subject.setvars(aug)
        end
      end
    end

    describe "#attr_aug_reader" do
      it "should create a class method using :string" do
        subject.attr_aug_reader(:foo, {})
        subject.method_defined?('attr_aug_reader_foo').should be_true

        Augeas.any_instance.expects(:get).with('$resource/foo').returns('bar')
        subject.augopen(resource) do |aug|
          subject.attr_aug_reader_foo(aug).should == 'bar'
        end
      end

      it "should create a class method using :array and no sublabel" do
        subject.attr_aug_reader(:foo, { :type => :array })
        subject.method_defined?('attr_aug_reader_foo').should be_true

        rpath = "/files#{thetarget}/test/foo"
        subject.augopen(resource) do |aug|
          aug.expects(:match).with('$resource/foo').returns(["#{rpath}[1]", "#{rpath}[2]"])
          aug.expects(:get).with("#{rpath}[1]").returns('baz')
          aug.expects(:get).with("#{rpath}[2]").returns('bazz')
          subject.attr_aug_reader_foo(aug).should == ['baz', 'bazz']
        end
      end

      it "should create a class method using :array and a :seq sublabel" do
        subject.attr_aug_reader(:foo, { :type => :array, :sublabel => :seq })
        subject.method_defined?('attr_aug_reader_foo').should be_true

        rpath = "/files#{thetarget}/test/foo"
        subject.augopen(resource) do |aug|
          aug.expects(:match).with('$resource/foo').returns(["#{rpath}[1]", "#{rpath}[2]"])
          aug.expects(:match).with("#{rpath}[1]/*[label()=~regexp('[0-9]+')]").returns(["#{rpath}[1]/1"])
          aug.expects(:get).with("#{rpath}[1]/1").returns('val11')
          aug.expects(:match).with("#{rpath}[2]/*[label()=~regexp('[0-9]+')]").returns(["#{rpath}[2]/1", "#{rpath}[2]/2"])
          aug.expects(:get).with("#{rpath}[2]/1").returns('val21')
          aug.expects(:get).with("#{rpath}[2]/2").returns('val22')
          subject.attr_aug_reader_foo(aug).should == ['val11', 'val21', 'val22']
        end
      end

      it "should create a class method using :array and a string sublabel" do
        subject.attr_aug_reader(:foo, { :type => :array, :sublabel => 'sl' })
        subject.method_defined?('attr_aug_reader_foo').should be_true

        rpath = "/files#{thetarget}/test/foo"
        subject.augopen(resource) do |aug|
          aug.expects(:match).with('$resource/foo').returns(["#{rpath}[1]", "#{rpath}[2]"])
          aug.expects(:match).with("#{rpath}[1]/sl").returns(["#{rpath}[1]/sl"])
          aug.expects(:get).with("#{rpath}[1]/sl").returns('val11')
          aug.expects(:match).with("#{rpath}[2]/sl").returns(["#{rpath}[2]/sl[1]", "#{rpath}[2]/sl[2]"])
          aug.expects(:get).with("#{rpath}[2]/sl[1]").returns('val21')
          aug.expects(:get).with("#{rpath}[2]/sl[2]").returns('val22')
          subject.attr_aug_reader_foo(aug).should == ['val11', 'val21', 'val22']
        end
      end

      it "should create a class method using :hash and no sublabel" do
        expect {
          subject.attr_aug_reader(:foo, { :type => :hash, :default => 'deflt' })
        }.to raise_error(RuntimeError, /You must provide a sublabel/)
      end

      it "should create a class method using :hash and sublabel" do
        subject.attr_aug_reader(:foo, { :type => :hash, :sublabel => 'sl', :default => 'deflt' })
        subject.method_defined?('attr_aug_reader_foo').should be_true

        rpath = "/files#{thetarget}/test/foo"
        subject.augopen(resource) do |aug|
          aug.expects(:match).with('$resource/foo').returns(["#{rpath}[1]", "#{rpath}[2]"])
          aug.expects(:get).with("#{rpath}[1]").returns('baz')
          aug.expects(:get).with("#{rpath}[1]/sl").returns('bazval')
          aug.expects(:get).with("#{rpath}[2]").returns('bazz')
          aug.expects(:get).with("#{rpath}[2]/sl").returns(nil)
          subject.attr_aug_reader_foo(aug).should == { 'baz' => 'bazval', 'bazz' => 'deflt' }
        end
      end

      it "should create a class method using wrong type" do
        expect {
          subject.attr_aug_reader(:foo, { :type => :foo })
        }.to raise_error(RuntimeError, /Invalid type: foo/)
      end
    end

    describe "#attr_aug_writer" do
      it "should create a class method using :string" do
        subject.attr_aug_writer(:foo, {})
        subject.method_defined?('attr_aug_writer_foo').should be_true

        subject.augopen(resource) do |aug|
          aug.expects(:set).with('$resource/foo', 'bar')
          subject.attr_aug_writer_foo(aug, 'bar')
          aug.expects(:clear).with('$resource/foo')
          subject.attr_aug_writer_foo(aug)
        end
      end

      it "should create a class method using :array and no sublabel" do
        subject.attr_aug_writer(:foo, { :type => :array })
        subject.method_defined?('attr_aug_writer_foo').should be_true

        subject.augopen(resource) do |aug|
          aug.expects(:rm).with('$resource/foo')
          aug.expects(:set).with('$resource/foo[1]', 'bar')
          subject.attr_aug_writer_foo(aug)
          aug.expects(:rm).with('$resource/foo')
          aug.expects(:set).with('$resource/foo[2]', 'baz')
          subject.attr_aug_writer_foo(aug, ['bar', 'baz'])
        end
      end

      it "should create a class method using :array and a :seq sublabel" do
        subject.attr_aug_writer(:foo, { :type => :array, :sublabel => :seq })
        subject.method_defined?('attr_aug_writer_foo').should be_true

        subject.augopen(resource) do |aug|
          aug.expects(:rm).with('$resource/foo')
          subject.attr_aug_writer_foo(aug)
          aug.expects(:rm).with("$resource/foo/*[label()=~regexp('[0-9]+')]")
          aug.expects(:set).with('$resource/foo/1', 'bar')
          aug.expects(:set).with('$resource/foo/2', 'baz')
          subject.attr_aug_writer_foo(aug, ['bar', 'baz'])
        end
      end

      it "should create a class method using :array and a string sublabel" do
        subject.attr_aug_writer(:foo, { :type => :array, :sublabel => 'sl' })
        subject.method_defined?('attr_aug_writer_foo').should be_true

        subject.augopen(resource) do |aug|
          aug.expects(:rm).with('$resource/foo')
          subject.attr_aug_writer_foo(aug)
          aug.expects(:rm).with('$resource/foo/sl')
          aug.expects(:set).with('$resource/foo/sl[1]', 'bar')
          aug.expects(:set).with('$resource/foo/sl[2]', 'baz')
          subject.attr_aug_writer_foo(aug, ['bar', 'baz'])
        end
      end

      it "should create a class method using :hash and no sublabel" do
        expect {
          subject.attr_aug_writer(:foo, { :type => :hash, :default => 'deflt' })
        }.to raise_error(RuntimeError, /You must provide a sublabel/)
      end

      it "should create a class method using :hash and sublabel" do
        subject.attr_aug_writer(:foo, { :type => :hash, :sublabel => 'sl', :default => 'deflt' })
        subject.method_defined?('attr_aug_writer_foo').should be_true

        rpath = "/files#{thetarget}/test/foo"
        subject.augopen(resource) do |aug|
          aug.expects(:rm).with('$resource/foo')
          aug.expects(:set).with("$resource/foo[.='baz']", 'baz')
          aug.expects(:set).with("$resource/foo[.='baz']/sl", 'bazval')
          aug.expects(:set).with("$resource/foo[.='bazz']", 'bazz')
          aug.expects(:set).with("$resource/foo[.='bazz']/sl", 'bazzval').never
          subject.attr_aug_writer_foo(aug, { 'baz' => 'bazval', 'bazz' => 'deflt' })
        end
      end

      it "should create a class method using wrong type" do
        expect {
          subject.attr_aug_writer(:foo, { :type => :foo })
        }.to raise_error(RuntimeError, /Invalid type: foo/)
      end
    end
  end
end
