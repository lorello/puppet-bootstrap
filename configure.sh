#!/usr/bin/env bash
#
# Configure puppet.conf
#
set -e

PUPPET_CERTNAME=${PUPPET_CERTNAME:-$(hostname -f)}
PUPPET_ENVIRONMENT=${PUPPET_ENVIRONMENT:-"test"}
PUPPET_ROOT_GROUP=${PUPPET_ROOT_GROUP:-"root"}

case "${PUPPET_ENVIRONMENT}" in
locdev|loctst|locprd|vagrant)        PUPPET_SERVER=${PUPPET_SERVER:-"localhost"} ;;
esodev|esotst)                       PUPPET_SERVER=${PUPPET_SERVER:-"puppet"} ;;
development|test|staging|production) PUPPET_SERVER=${PUPPET_SERVER:-"puppet"} ;;
*)
  echo "Unknown/Unsupported PUPPET_ENVIRONMENT." >&2
  exit 1
esac

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

echo "Running conf with the following settings:"
echo "PUPPET_ENVIRONMENT=${PUPPET_ENVIRONMENT}"
echo "PUPPET_CERTNAME=${PUPPET_CERTNAME}"
echo "PUPPET_ROOT_GROUP=${PUPPET_ROOT_GROUP}"
echo "PUPPET_SERVER=${PUPPET_SERVER}"
echo "PUPPET_COLLECTION=${PUPPET_COLLECTION}"

if [[ "${PUPPET_COLLECTION}" == "" ]]; then
  PCONF="/etc/puppet/puppet.conf"
  var_dir='/var/lib/puppet'
  log_dir='/var/log/puppet'
  run_dir='/var/run/puppet'
  ssl_dir='$vardir/ssl'
  extra_a_options='
    stringify_facts = false'
  extra_u_options='
    parser          = future
    stringify_facts = false
    ordering        = manifest'
else
  PCONF="/etc/puppetlabs/puppet/puppet.conf"
  var_dir='/opt/puppetlabs/puppet/cache'
  log_dir='/var/log/puppetlabs/puppet'
  run_dir='/var/run/puppetlabs'
  ssl_dir='/etc/puppetlabs/puppet/ssl'
  extra_a_options=''
  extra_u_options=''
fi

echo "Configuring Puppet..."
cat > ${PCONF} <<-EOF
### File placed by puppet-bootstrap ###
## https://docs.puppet.com/puppet/latest/reference/configuration.html
#

[main]
    vardir = ${var_dir}
    logdir = ${log_dir}
    rundir = ${run_dir}
    ssldir = ${ssl_dir}

[agent]
    pluginsync      = true
    report          = true
    ignoreschedules = true
    daemon          = false
    ca_server       = ${PUPPET_SERVER}
    certname        = ${PUPPET_CERTNAME}
    environment     = ${PUPPET_ENVIRONMENT}
    server          = ${PUPPET_SERVER}${extra_a_options}

[user]
    environment     = ${PUPPET_ENVIRONMENT}${extra_u_options}
EOF
chown root:${PUPPET_ROOT_GROUP} ${PCONF}
chmod 0644 ${PCONF}
