# Class: augeasproviders::instances: See README.md for documentation
#
# [Remember: No empty lines between comments and class definition]
class augeasproviders::instances (
  Hash[String, Hash] $apache_directive_hash      = {},
  Hash[String, Hash] $apache_setenv_hash         = {},
  Hash[String, Hash] $host_hash                  = {},
  Hash[String, Hash] $kernel_parameter_hash      = {},
  Hash[String, Hash] $mailalias_hash             = {},
  Hash[String, Hash] $mounttab_hash              = {},
  Hash[String, Hash] $nrpe_command_hash          = {},
  Hash[String, Hash] $pam_hash                   = {},
  Hash[String, Hash] $pg_hba_hash                = {},
  Hash[String, Hash] $puppet_auth_hash           = {},
  Hash[String, Hash] $shellvar_hash              = {},
  Hash[String, Hash] $ssh_config_hash            = {},
  Hash[String, Hash] $sshd_config_hash           = {},
  Hash[String, Hash] $sshd_config_subsystem_hash = {},
  Hash[String, Hash] $sysctl_hash                = {},
  Hash[String, Hash] $syslog_hash                = {},
  Hash[String, Hash] $resource_defaults          = $augeasproviders::params::resource_defaults,
) inherits augeasproviders::params {
  create_resources(apache_directive, $apache_directive_hash, $resource_defaults['apache_directive'])
  create_resources(apache_setenv, $apache_setenv_hash, $resource_defaults['apache_setenv'])
  create_resources(host, $host_hash, $resource_defaults['host'])
  create_resources(kernel_parameter, $kernel_parameter_hash, $resource_defaults['kernel_parameter'])
  create_resources(mailalias, $mailalias_hash, $resource_defaults['mailalias'])
  create_resources(mounttab, $mounttab_hash, $resource_defaults['mounttab'])
  create_resources(nrpe_command, $nrpe_command_hash, $resource_defaults['nrpe_command'])
  create_resources(pam, $pam_hash, $resource_defaults['pam'])
  create_resources(pg_hba, $pg_hba_hash, $resource_defaults['pg_hba'])
  create_resources(puppet_auth, $puppet_auth_hash, $resource_defaults['puppet_auth'])
  create_resources(shellvar, $shellvar_hash, $resource_defaults['shellvar'])
  create_resources(ssh_config, $ssh_config_hash, $resource_defaults['ssh_config'])
  create_resources(sshd_config, $sshd_config_hash, $resource_defaults['sshd_config'])
  create_resources(sshd_config_subsystem, $sshd_config_subsystem_hash, $resource_defaults['sshd_config_subsystem'])
  create_resources(sysctl, $sysctl_hash, $resource_defaults['sysctl'])
  create_resources(syslog, $syslog_hash, $resource_defaults['syslog'])
}
