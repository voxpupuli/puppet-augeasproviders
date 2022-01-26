# Class: augeasproviders::augeasproviders_params
#
# Defines all the variables used in the module.
#
class augeasproviders::params {

  $apache_directive_hash = lookup({
    'name'          => 'augeasproviders_apache_directive_hash',
    'value_type'    => Hash,
    'default_value' => {},
  })

  $apache_setenv_hash = lookup({
    'name'          => 'augeasproviders_apache_setenv_hash',
    'value_type'    => Hash,
    'default_value' => {},
  })

  $host_hash = lookup({
    'name'          => 'augeasproviders_host_hash',
    'value_type'    => Hash,
    'default_value' => {},
  })

  $kernel_parameter_hash = lookup({
    'name'          => 'augeasproviders_kernel_parameter_hash',
    'value_type'    => Hash,
    'default_value' => {},
  })

  $mailalias_hash = lookup({
    'name'          => 'augeasproviders_mailalias_hash',
    'value_type'    => Hash,
    'default_value' => {},
  })

  $mounttab_hash = lookup({
    'name'          => 'augeasproviders_mounttab_hash',
    'value_type'    => Hash,
    'default_value' => {},
  })

  $nrpe_command_hash = lookup({
    'name'          => 'augeasproviders_nrpe_command_hash',
    'value_type'    => Hash,
    'default_value' => {},
  })

  $pam_hash = lookup({
    'name'          => 'augeasproviders_pam_hash',
    'value_type'    => Hash,
    'default_value' => {},
  })

  $pg_hba_hash = lookup({
    'name'          => 'augeasproviders_pg_hba_hash',
    'value_type'    => Hash,
    'default_value' => {},
  })

  $puppet_auth_hash = lookup({
    'name'          => 'augeasproviders_puppet_auth_hash',
    'value_type'    => Hash,
    'default_value' => {},
  })

  $shellvar_hash = lookup({
    'name'          => 'augeasproviders_shellvar_hash',
    'value_type'    => Hash,
    'default_value' => {},
  })

  $ssh_config_hash = lookup({
    'name'          => 'augeasproviders_ssh_config_hash',
    'value_type'    => Hash,
    'default_value' => {},
  })

  $sshd_config_hash = lookup({
    'name'          => 'augeasproviders_sshd_config_hash',
    'value_type'    => Hash,
    'default_value' => {},
  })

  $sshd_config_subsystem_hash = lookup({
    'name'          => 'augeasproviders_sshd_config_subsystem_hash',
    'value_type'    => Hash,
    'default_value' => {},
  })

  $sysctl_hash = lookup({
    'name'          => 'augeasproviders_sysctl_hash',
    'value_type'    => Hash,
    'default_value' => {},
  })

  $syslog_hash = lookup({
    'name'          => 'augeasproviders_syslog_hash',
    'value_type'    => Hash,
    'default_value' => {},
  })

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
