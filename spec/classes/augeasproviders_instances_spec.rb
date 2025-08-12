# frozen_string_literal: true

require 'spec_helper'

describe 'augeasproviders::instances' do
  it { is_expected.to create_class('augeasproviders::instances') }
  it { is_expected.to contain_class('augeasproviders::params') }

  context "when resource_defaults => 'foo'" do
    let(:params) { { resource_defaults: 'foo' } }

    it { is_expected.to compile.and_raise_error(%r{expects a Hash value, got String}) }
  end

  %w[
    apache_directive
    apache_setenv
    host
    kernel_parameter
    mailalias
    mounttab
    nrpe_command
    pam
    pg_hba
    puppet_auth
    shellvar
    sshd_config
    sshd_config_subsystem
    sysctl
    syslog
  ].each do |type|
    describe "#{type} instances" do
      include_context type

      include_examples 'validate_hash param', "#{type}_hash"
    end
  end
end
