# This class provides an alternative way to create resources for all of the
# augeasproviders types. Instead of creating the resources directly, you can
# instead pass hashes of resources to this class. This is especially useful
# when you want to create these resources from Hiera.
#
# @summary An alternative way to create resources for all augeasproviders types.
#
# @param apache_directive_hash Hash of apache_directive resources to create.
# @param apache_setenv_hash Hash of apache_setenv resources to create.
# @param host_hash Hash of host resources to create.
# @param kernel_parameter_hash Hash of kernel_parameter resources to create.
# @param mailalias_hash Hash of mailalias resources to create.
# @param mounttab_hash Hash of mounttab resources to create.
# @param nrpe_command_hash Hash of nrpe_command resources to create.
# @param pam_hash Hash of pam resources to create.
# @param pg_hba_hash Hash of pg_hba resources to create.
# @param puppet_auth_hash Hash of puppet_auth resources to create.
# @param shellvar_hash Hash of shellvar resources to create.
# @param ssh_config_hash Hash of ssh_config resources to create.
# @param sshd_config_hash Hash of sshd_config resources to create.
# @param sshd_config_subsystem_hash Hash of sshd_config_subsystem resources to create.
# @param sysctl_hash Hash of sysctl resources to create.
# @param syslog_hash Hash of syslog resources to create.
# @param resource_defaults Default values for the created resources.
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
