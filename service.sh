#!/usr/bin/env bash
#
# Start the Puppet Service or Cron
#
set -e

PUPPET_ENVIRONMENT=${PUPPET_ENVIRONMENT:-"test"}
PUPPET_SCHEDULE=${PUPPET_SCHEDULE:-"none"}

echo "------------------------------------------"
echo "Running $0 with the following settings:"
echo "PUPPET_ENVIRONMENT=${PUPPET_ENVIRONMENT}"
echo "PUPPET_SCHEDULE=${PUPPET_SCHEDULE}"
echo "------------------------------------------"


if [[ "${PUPPET_COLLECTION}" == "" ]]; then
  PCONF="/etc/puppet/puppet.conf"
  PMANIFESTS="/etc/puppet/manifests"
  puppet_cmd='/usr/bin/puppet'
  logdest='/var/log/puppet/puppet.log'
else
  PCONF="/etc/puppetlabs/puppet/puppet.conf"
  PMANIFESTS="/etc/puppetlabs/code/environments/${PUPPET_ENVIRONMENT}/manifests"
  puppet_cmd='/opt/puppetlabs/bin/puppet'
  logdest='/var/log/puppetlabs/pxp-agent/puppet.log'
fi

case "${PUPPET_ENVIRONMENT}" in
locdev|loctst|locprd|vagrant)
  PUPPET_CRON_CMD=${PUPPET_CRON_CMD:-"${puppet_cmd} apply --config ${PCONF} --logdest ${logdest} ${PMANIFESTS}"}
  ;;
*)
  PUPPET_CRON_CMD=${PUPPET_CRON_CMD:-"${puppet_cmd} agent --config ${PCONF} --onetime --no-daemonize"}
  ;;
esac

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

if [ "$PUPPET_SCHEDULE" == "service" ]; then
  # Start the Puppet Agent Service
  echo "Starting Puppet Agent..."
  puppet resource service puppet ensure=running enable=true
elif [ "$PUPPET_SCHEDULE" == "cron" ]; then
  # Create a Cron Job Instead
  echo "Configure Puppet Cron..."
  puppet resource service puppet ensure=stopped enable=false
  puppet resource cron puppet ensure=present command="${PUPPET_CRON_CMD}" user=root minute=0
else
  echo "No scheduling of puppet execution required, run yourself"
  puppet resource service puppet ensure=stopped enable=false
  puppet resource cron puppet ensure=absent command="${PUPPET_CRON_CMD}" user=root minute=0
fi

# Force a run to generate ssl sign request
# puppet agent --test || true
