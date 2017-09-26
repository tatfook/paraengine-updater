#!/usr/bin/env bash

# gather all the ci phase into a project
phases=(asset_ABupdate assetupdate client_pkg ABClntFullpkgUpdate \
  client_pkg_patch ABClientpkgUpdate coreUpdate HaqiClient_installer \
  PublishClientPkgToCDN PublishVerFileToCDN)

usage() {
  echo "$0 phase"
  echo "phases:"
  for p in ${phases[@]}; do
    echo "- $p"
  done
}

if [[ $# != 1 ]]; then
  usage
  exit 1
fi

if [[ ! -d $1 ]]; then
  usage
  exit 1
fi

prequisite() {
  # mount paraenginesdk
  mount_dirs=(installer Texture model character ParaEngineSDK)
  for d in ${mount_dirs[@]}; do
    mkdir -p /mnt/$d

    # if /mnt/$d is mounted
    if mount | grep /mnt/$d > /dev/null; then
      echo "/mnt/$d is mounted"
    else
      sudo mount -t cifs -o password=paraengine //192.168.0.241/$d /mnt/$d
    fi
  done
}

prequisite

pushd $1
./main.sh
popd
