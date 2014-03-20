shared_examples_for 'validate_hash param' do |hash_param_name|
  context "when #{hash_param_name} => 'FOO'" do
    let(:params) {{ hash_param_name.to_sym => 'FOO' }}
    let(:facts) {{}}
    it { expect { should create_class('augeasproviders') }.to raise_error(Puppet::Error, /is not a Hash/) }
  end
end

shared_examples_for 'validate_hash top-scope param' do |hash_variable_name|
  context "when ::#{hash_variable_name} => 'FOO'" do
    let(:params) {{}}
    let(:facts) {{ hash_variable_name.to_sym => 'FOO' }}
    it { expect { should create_class('augeasproviders') }.to raise_error(Puppet::Error, /is not a Hash/) }
  end
end
