#!/usr/bin/env bash
#
# Bootstrap script to install/config/start puppet on multi POSIX platforms
#
set -e

BOOTSTRAP_HOME=${BOOTSTRAP_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
PLATFORM=${PLATFORM:-$1}
PUPPET_ENVIRONMENT=${PUPPET_ENVIRONMENT:-$2}
PUPPET_COLLECTION=${PUPPET_COLLECTION:-$3}
PUPPET_SERVER=${PUPPET_SERVER:-$4}

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

if [ "${PUPPET_ENVIRONMENT}" != "vagrant" ]; then
  # Remove any detected legacy puppet installs
  source "${BOOTSTRAP_HOME}/legacy.sh"
fi

# Install Puppet Using the Puppet Labs Package Repositories
case "${PLATFORM}" in
redhat_5|centos_5|centos_5_x) source "${BOOTSTRAP_HOME}/centos_5_x.sh" ;;
redhat_6|centos_6|centos_6_x) source "${BOOTSTRAP_HOME}/centos_6_x.sh" ;;
redhat_7|centos_7|centos_7_x) source "${BOOTSTRAP_HOME}/centos_7_x.sh" ;;
amazonlinux) source "${BOOTSTRAP_HOME}/amazonlinux.sh" ;;
debian) source "${BOOTSTRAP_HOME}/debian.sh" ;;
ubuntu) source "${BOOTSTRAP_HOME}/ubuntu.sh" ;;
osx|mac_os_x)
  PUPPET_ROOT_GROUP=${PUPPET_ROOT_GROUP:-"wheel"}
  source "${BOOTSTRAP_HOME}/mac_os_x.sh"
  ;;
*)
  echo "Unknown/Unsupported PLATFORM." >&2
  echo "Usage: $0 {redhat_5|redhat_6|redhat_7|amazonlinux|debian|ubuntu|osx} [environment] [server]" >&2
  exit 1
esac

# Post Install Cleanup
source "${BOOTSTRAP_HOME}/postinstall.sh"

if [ "${PUPPET_ENVIRONMENT}" != "vagrant" ]; then
  # Configure puppet.conf
  source "${BOOTSTRAP_HOME}/configure.sh"

  # Start the Puppet Service or Cron
  source "${BOOTSTRAP_HOME}/service.sh"
fi

echo "Success!!"
