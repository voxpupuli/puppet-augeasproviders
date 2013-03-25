#!/bin/bash
set -xe

# Clone submodules in tree
git submodule update --init

# Use latest Augeas
sudo add-apt-repository -y ppa:raphink/augeas
sudo apt-get update
sudo apt-get install augeas-tools libaugeas-dev libxml2-dev

# Install gems, but use the latest or those set by ENV not Gemfile.lock
rm Gemfile.lock
gem install bundler
bundle install

# Reporting only
bundle show
puppet --version
augtool --version
