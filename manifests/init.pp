# Class: augeasproviders
#
# This module manages augeasproviders
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# [Remember: No empty lines between comments and class definition]
class augeasproviders {
  gem { 'augeasproviders':
    ensure => 'installed',
  }

  # Existing types
  Gem['augeasproviders'] -> Host <||>
  Gem['augeasproviders'] -> Mailalias <||>
  Gem['augeasproviders'] -> Mounttab <||>

  # Additional types
  Gem['augeasproviders'] -> Apache_setenv <||>
  Gem['augeasproviders'] -> Kernel_parameter <||>
  Gem['augeasproviders'] -> Nrpe_command <||>
  Gem['augeasproviders'] -> Pg_hba <||>
  Gem['augeasproviders'] -> Puppet_auth <||>
  Gem['augeasproviders'] -> Shellvar <||>
  Gem['augeasproviders'] -> Sshd_config <||>
  Gem['augeasproviders'] -> Sshd_config_subsystem <||>
  Gem['augeasproviders'] -> Sysctl <||>
  Gem['augeasproviders'] -> Syslog <||>
}
