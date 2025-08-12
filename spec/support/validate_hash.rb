# frozen_string_literal: true

shared_examples_for 'validate_hash param' do |hash_param_name|
  context "when #{hash_param_name} => 'FOO'" do
    let(:params) { { hash_param_name.to_sym => 'FOO' } }
    let(:facts) { {} }

    it { expect { is_expected.to create_class('augeasproviders') }.to raise_error(Puppet::Error, %r{expects a Hash value, got String}) }
  end
end
