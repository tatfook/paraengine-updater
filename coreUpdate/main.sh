#!/usr/bin/env bash

# run on server.240, linux
#
# step
# 1. ./CoreUpdate.sh (240:/opt/hudson_conf/ci_shell/Client/CoreUpdate.sh)
#

ln -sf /mnt/ParaEngineSDK ParaEngineSDK

./CoreUpdate.sh

exit 0
