# Class: augeasproviders::augeasproviders_params
#
# Defines all the variables used in the module.
#
class augeasproviders::params {

  $apache_directive_hash = $facts['augeasproviders_apache_directive_hash'] ? {
    undef   => false,
    default => $::augeasproviders_apache_directive_hash,
  }

  $apache_setenv_hash = $facts['augeasproviders_apache_setenv_hash'] ? {
    undef   => false,
    default => $::augeasproviders_apache_setenv_hash,
  }

  $host_hash = $facts['augeasproviders_host_hash'] ? {
    undef   => false,
    default => $::augeasproviders_host_hash,
  }

  $kernel_parameter_hash = $facts['augeasproviders_kernel_parameter_hash'] ? {
    undef   => false,
    default => $::augeasproviders_kernel_parameter_hash,
  }

  $mailalias_hash = $facts['augeasproviders_mailalias_hash'] ? {
    undef   => false,
    default => $::augeasproviders_mailalias_hash,
  }

  $mounttab_hash = $facts['augeasproviders_mounttab_hash'] ? {
    undef   => false,
    default => $::augeasproviders_mounttab_hash,
  }

  $nrpe_command_hash = $facts['augeasproviders_nrpe_command_hash'] ? {
    undef   => false,
    default => $::augeasproviders_nrpe_command_hash,
  }

  $pam_hash = $facts['augeasproviders_pam_hash'] ? {
    undef   => false,
    default => $::augeasproviders_pam_hash,
  }

  $pg_hba_hash = $facts['augeasproviders_pg_hba_hash'] ? {
    undef   => false,
    default => $::augeasproviders_pg_hba_hash,
  }

  $puppet_auth_hash = $facts['augeasproviders_puppet_auth_hash'] ? {
    undef   => false,
    default => $::augeasproviders_puppet_auth_hash,
  }

  $shellvar_hash = $facts['augeasproviders_shellvar_hash'] ? {
    undef   => false,
    default => $::augeasproviders_shellvar_hash,
  }

  $ssh_config_hash = $facts['augeasproviders_ssh_config_hash'] ? {
    undef   => false,
    default => $::augeasproviders_ssh_config_hash,
  }

  $sshd_config_hash = $facts['augeasproviders_sshd_config_hash'] ? {
    undef   => false,
    default => $::augeasproviders_sshd_config_hash,
  }

  $sshd_config_subsystem_hash = $facts['augeasproviders_sshd_config_subsystem_hash'] ? {
    undef   => false,
    default => $::augeasproviders_sshd_config_subsystem_hash,
  }

  $sysctl_hash = $facts['augeasproviders_sysctl_hash'] ? {
    undef   => false,
    default => $::augeasproviders_sysctl_hash,
  }

  $syslog_hash = $facts['augeasproviders_syslog_hash'] ? {
    undef   => false,
    default => $::augeasproviders_syslog_hash,
  }

  $defaults = {
    'ensure'    => 'present',
    'provider'  => 'augeas',
  }

  $resource_defaults = {
    'apache_directive'      => $defaults,
    'apache_setenv'         => $defaults,
    'host'                  => $defaults,
    'kernel_parameter'      => merge($defaults, {'provider' => undef}),
    'mailalias'             => $defaults,
    'mounttab'              => $defaults,
    'nrpe_command'          => $defaults,
    'pam'                   => $defaults,
    'pg_hba'                => $defaults,
    'puppet_auth'           => $defaults,
    'shellvar'              => $defaults,
    'sshd_config'           => $defaults,
    'sshd_config_subsystem' => $defaults,
    'sysctl'                => $defaults,
    'syslog'                => $defaults,
  }

}
