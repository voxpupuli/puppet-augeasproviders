require 'spec_helper'

describe 'augeasproviders::instances' do
  it { should create_class('augeasproviders::instances') }
  it { should contain_class('augeasproviders::params') }

  context "when resource_defaults => 'foo'" do
    let(:params) {{ :resource_defaults => 'foo' }}
    it { expect { should create_class('augeasproviders::instances') }.to raise_error(Puppet::Error, /is not a Hash/) }
  end

  [
    'apache_directive',
    'apache_setenv',
    'host',
    'kernel_parameter',
    'mailalias',
    'mounttab',
    'nrpe_command',
    'pam',
    'pg_hba',
    'puppet_auth',
    'shellvar',
    'sshd_config',
    'sshd_config_subsystem',
    'sysctl',
    'syslog',
  ].each do |type|
    describe "#{type} instances" do
      include_context type

      include_examples 'validate_hash param', "#{type}_hash"
      include_examples 'validate_hash top-scope param', "augeasproviders_#{type}_hash"
    end
  end
end
