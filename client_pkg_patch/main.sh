#!/usr/bin/env bash

# run in server.25, linux

# steps
# 1. svn update svn://svn.paraengine.com/script/trunk
# YDD:YDDParaEngine
#
# 2. call ./get_pkg_patch.sh 17798
# server.25:/var/lib/hudson/jobs/client_pkg_patch/get_pkg_patch.sh
#
# result
# nothing left
# 1. gen main.pkg and copy to /mnt/??

prequisite() {
  # 1. mount paraenginesdk
  mount_dirs=(installer Texture model character ParaEngineSDK)
  for d in ${mount_dirs[@]}; do
    mkdir -p /mnt/$d

    # if /mnt/$d is mounted
    if mount | grep /mnt/$d > /dev/null; then
      echo "/mnt/$d is mounted"
    else
      mount -t cifs -o password=paraengine //192.168.0.241/$d /mnt/$d
    fi
  done
}

prequisite

# svn checkout code
# it'll auto update repo
svn checkout --username YDD --password YDDParaEngine --depth infinity \
  svn://svn.paraengine.com/script/trunk paraengine.svn

./get_pkg_patch.sh 17798
