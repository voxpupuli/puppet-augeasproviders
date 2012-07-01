require 'augeas'

module AugeasSpec::Fixtures
  # Creates a temp file from a given fixture name
  # Doesn't explicitly clean up the temp file as we can't evaluate a block with
  # "let" or pass the path back via an "around" hook.
  def aug_fixture(name)
    tmp = Tempfile.new("target")
    tmp.write(File.read(my_fixture(name)))
    tmp.close
    return tmp
  end

  # Runs a particular resource via a catalog
  def apply(resource)
    catalog = Puppet::Resource::Catalog.new
    catalog.add_resource resource
    txn = catalog.apply

    # Check for warning+ log messages
    loglevels = Puppet::Util::Log.levels[3, 999]
    @logs.select { |log| loglevels.include? log.level }.should == []

    # Check for transaction success after, as it's less informative
    txn.any_failed?.should == nil
  end

  # Open Augeas on a given file.  Used for testing the results of running
  # Puppet providers.
  def aug_open(file, lens, &block)
    aug = Augeas.open(nil, nil, Augeas::NO_MODL_AUTOLOAD)
    begin
      aug.transform(
        :lens => lens,
        :name => lens.split(".")[0],
        :incl => file
      )
      aug.set("/augeas/context", "/files#{file}")
      aug.load!
      raise LoadError("Augeas didn't load #{file}") if aug.match(".").empty?
      yield aug
    ensure
      aug.close
    end
  end
end
