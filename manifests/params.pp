# Class: augeasproviders::augeasproviders_params
#
# Sets defaults behaviour to all directives
#
class augeasproviders::params {
  $defaults = {
    'ensure'    => 'present',
    'provider'  => 'augeas',
  }

  $resource_defaults = {
    'apache_directive'      => $defaults,
    'apache_setenv'         => $defaults,
    'host'                  => $defaults,
    'kernel_parameter'      => merge($defaults, { 'provider' => undef }),
    'mailalias'             => $defaults,
    'mounttab'              => $defaults,
    'nrpe_command'          => $defaults,
    'pam'                   => $defaults,
    'pg_hba'                => $defaults,
    'puppet_auth'           => $defaults,
    'shellvar'              => $defaults,
    'ssh_config'            => $defaults,
    'sshd_config'           => $defaults,
    'sshd_config_subsystem' => $defaults,
    'sysctl'                => $defaults,
    'syslog'                => $defaults,
  }
  # lint:endignore
}
