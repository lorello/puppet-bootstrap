#!/usr/bin/env bash
#
# Bootstrap express script to install/config/start puppet on multi POSIX platforms
# with one line
#
set -e

BOOTSTRAP_TAR_URL=${BOOTSTRAP_TAR_URL:-"https://github.com/lorello/puppet-bootstrap/archive/master.tar.gz"}
PLATFORM=${PLATFORM:-$1}

# Attempt to Detect PLATFORM if not set
if [ -z "${PLATFORM}" ]; then
  case "$(uname -s)" in
  Darwin)
    PLATFORM="mac_os_x"
    echo "[Mac OS X Detected]"
    ;;
  Linux)
    # is lsb available to detect distribution info?
    if hash lsb_release 2>/dev/null; then
      lsb_id=$(lsb_release -is)
      lsb_re=$(lsb_release -rs | cut -f1 -d'.')
      case "${lsb_id}" in
      RedHatEnterpriseServer|CentOS|OracleServer|EnterpriseEnterpriseServer)
        PLATFORM="centos_${lsb_re}_x"
        echo "[${lsb_id} ${lsb_re} Detected]"
        ;;
      Ubuntu)
        PLATFORM="ubuntu"
        echo "[${lsb_id} ${lsb_re} Detected]"
        ;;
      esac
    elif [ -e /etc/redhat-release ]; then
      etcrh_re=$(cat /etc/redhat-release | grep -o [0-9] | head -n 1)
      PLATFORM="centos_${etcrh_re}_x"
      echo "[Redhat ${etcrh_re} Detected]"
    elif [ -e /etc/system-release ]; then
      	amzn_re=$(egrep -o '[0-9]{4}\.[0-9]{2}' /etc/system-release | head -n 1);
        echo "[Amazon Linux ${amzn_re} Detected]"
      	PLATFORM="amazonlinux"
    fi
    ;;
  esac
fi

bootstrap_tmp_path=$(mktemp -d -t puppet-bootstrap.XXXXXXXXXX)
\curl -sSL "${BOOTSTRAP_TAR_URL}" > /tmp/puppet-bootstrap.tar.gz
if [ ! -f /tmp/puppet-bootstrap.tar.gz ]; then
	echo "Error downloading file '${BOOTSTRAP_TAR_URL}' to /tmp/puppet-bootstrap.tar.gz"
	rm -rf $bootstrap_tmp_path
	exit 1
fi
tar xz --directory="${bootstrap_tmp_path}" --file="/tmp/puppet-bootstrap.tar.gz"
if [ ! -f "${bootstrap_tmp_path}/puppet-bootstrap-master/bootstrap.sh" ]; then
	echo "Error decompressing /tmp/puppet-bootstrap.tar.gz to ${bootstrap_tmp_path}"
	exit 2
fi
source "${bootstrap_tmp_path}/puppet-bootstrap-master/bootstrap.sh" "$@"

rm -rf /tmp/puppet-bootstrap.tar.gz ${bootstrap_tmp_path}

