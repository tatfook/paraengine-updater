#!/usr/bin/env bash

# run on server.25

svn update --username svr233 --password svr233ParaEngine /opt/hudson_conf/ci_shell
cd /opt/hudson_conf/ci_shell/Client

/var/lib/hudson/jobs/client_pkg_patch/get_pkg_full.sh
rm -rf /opt/config_bak/config
cp /mnt/ParaEngineSDK/config /opt/config_bak -r

exit 0
