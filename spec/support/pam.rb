shared_examples_for 'pam resource' do
  it { should have_pam_resource_count(1) }

  it do
    should contain_pam('Add pam_test.so to auth for system-auth').only_with({
      'name'      => 'Add pam_test.so to auth for system-auth',
      'service'   => 'system-auth',
      'type'      => 'auth',
      'control'   => 'sufficient',
      'module'    => 'pam_test.so',
      'arguments' => 'test_me_out',
      'position'  => 'before module pam_deny.so',
      'target'    => '/etc/pam.d/system-auth',
      'provider'  => 'augeas',
      'ensure'    => 'present',
    })
  end
end

shared_context 'pam' do
  it { should have_pam_resource_count(0) }

  let :example_params do
    { 'Add pam_test.so to auth for system-auth' => {'service' => 'system-auth', 'type' => 'auth', 'control' => 'sufficient', 'module' => 'pam_test.so', 'arguments' => 'test_me_out', 'position' => 'before module pam_deny.so', 'target' => '/etc/pam.d/system-auth', 'provider' => 'augeas', 'ensure' => 'present'}}
  end

  context  "when pam_hash is a Hash" do
    let(:params) {{ :pam_hash => example_params }}
    let(:facts) {{}}

    include_examples 'pam resource'
  end

  context "when ::augeasproviders_pam_hash is a Hash" do
    let(:params) {{}}
    let(:facts) {{ :augeasproviders_pam_hash => example_params }}

    include_examples 'pam resource'
  end
end
