require 'augeas'

module AugeasSpec::Fixtures
  # Creates a temp file from a given fixture name
  # Doesn't explicitly clean up the temp file as we can't evaluate a block with
  # "let" or pass the path back via an "around" hook.
  def aug_fixture(name)
    tmp = Tempfile.new("target")
    tmp.write(File.read(my_fixture(name)))
    tmp.close
    return tmp.path
  end

  # Runs a particular resource via a catalog
  def apply(resource)
    catalog = Puppet::Resource::Catalog.new
    catalog.add_resource resource
    catalog.apply
  end

  # Open Augeas on a given file.  Used for testing the results of running
  # Puppet providers.
  def aug_open(file, lens, &block)
    aug = Augeas.open(nil, nil, Augeas::NO_LOAD)
    begin
      aug.set("/augeas/load/#{lens.split(".")[0]}/lens", lens)
      aug.set("/augeas/load/#{lens.split(".")[0]}/incl", file)
      aug.set("/augeas/context", "/files#{file}")
      aug.load
      raise LoadError("Augeas didn't load #{file}") if aug.match(".").empty?
      yield aug
    ensure
      aug.close
    end
  end
end
