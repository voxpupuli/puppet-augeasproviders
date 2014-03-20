shared_examples_for 'shellvar resource' do
  it { should have_shellvar_resource_count(1) }

  it do
    should contain_shellvar('HOSTNAME').only_with({
      'variable'  => 'HOSTNAME',
      'ensure'    => 'present',
      'target'    => '/etc/sysconfig/network',
      'value'     => 'host.example.com',
      'provider'  => 'augeas',
    })
  end
end

shared_context 'shellvar' do
  it { should have_shellvar_resource_count(0) }

  let :example_params do
    {'HOSTNAME' => {'target' => '/etc/sysconfig/network', 'value' => 'host.example.com'}}
  end

  context  "when shellvar_hash is a Hash" do
    let(:params) {{ :shellvar_hash => example_params }}
    let(:facts) {{}}

    include_examples 'shellvar resource'
  end

  context "when ::augeasproviders_shellvar_hash is a Hash" do
    let(:params) {{}}
    let(:facts) {{ :augeasproviders_shellvar_hash => example_params }}

    include_examples 'shellvar resource'
  end
end
