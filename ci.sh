#!/usr/bin/env bash

# gather all the ci phase into a project
phases=(asset_ABupdate assetupdate client_pkg ABClntFullpkgUpdate client_pkg_patch ABClientpkgUpdate coreUpdate HaqiClient_installer)

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
