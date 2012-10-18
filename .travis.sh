#!/bin/bash
set -xe

# Clone submodules in tree
git submodule update --init

# Use latest Augeas
sudo add-apt-repository -y ppa:raphink/augeas
sudo apt-get update
sudo apt-get install augeas-tools libaugeas-dev libxml2-dev

# Workaround for provider confinement on aliases
sudo touch /etc/aliases
sudo touch /etc/syslog.conf
sudo mkdir /etc/nagios
sudo touch /etc/nagios/nrpe.cfg

# Install gems, but use the latest or those set by ENV not Gemfile.lock
rm Gemfile.lock
gem install bundler
bundle install

# Install puppet modules, preferably using librarian-puppet but that relies
# on 2.7.12+ for `puppet module` so otherwise ignore and skip those specs
if [[ $PUPPET_VERSION =~ ^(0.2|2.6) ]]; then
    [ -d modules ] || mkdir modules
    gem install puppet-module
    ( cd modules && puppet-module install puppetlabs-mount_providers )
else
    librarian-puppet install
fi

# Reporting only
bundle show
puppet --version
augtool --version
