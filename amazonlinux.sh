#!/usr/bin/env bash
# Bootstrap Puppet on Amazon Linux 
# Tested on Amazon Linux 2015.09, 2016.03 

set -e

# if PUPPET_COLLECTION is not prepended with a dash "-", add it
[[ "${PUPPET_COLLECTION}" == "" ]] || [[ "${PUPPET_COLLECTION:0:1}" == "-" ]] || \
  PUPPET_COLLECTION="-${PUPPET_COLLECTION}"
[[ "${PUPPET_COLLECTION}" == "" ]] && PINST="puppet" || PINST="puppet-agent"

PUPPETLABS_RELEASE_RPM="https://yum.puppetlabs.com/puppetlabs-release${PUPPET_COLLECTION}-el-6.noarch.rpm"

PATH=$PATH:/opt/puppetlabs/bin
if [ "${EUID}" -ne "0" ]; then
  echo "This script must be run as root." >&2
  exit 1
elif rpm --quiet -q ${PINST}; then
  echo "Puppet $(puppet --version) is already installed."
  exit 0
fi

# Install Puppet Labs repo
echo "Configuring PuppetLabs repo..."
rpm --quiet -i "${PUPPETLABS_RELEASE_RPM}"

# Install Puppet
echo "Installing Puppet..."
yum install -q -y ${PINST}

echo "Puppet installed!"
