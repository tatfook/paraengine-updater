#!/usr/bin/env bash

# gather all the ci phase into a project
phases=(asset_ABupdate assetupdate \
# client_pkg ABClntFullpkgUpdate \
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
  if [[ ! -d ./asset_ABupdate/paracraft ]]; then
    echo "you need to run ./asset_ABupdate/main.sh first!"
    exit 2
  fi

  script_path=$(realpath $0)
  script_dir=$(dirname $script_path)
  paracraft_dir=$script_dir/asset_ABupdate/paracraft

  ln -sf $paracraft_dir /mnt/ParaEngineSDK
  ln_dirs=(installer Texture model character Database)
  for d in ${ln_dirs[@]}; do
    ln -sf $paracraft_dir/$d /mnt/$d
  done
}

prequisite

pushd $1
./main.sh
popd
