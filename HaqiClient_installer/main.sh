#!/usr/bin/env bash

# need makensis program
# sudo apt install nsis
#
# map   ./Haqi  ===  server.240:/opt/haqi_install/Haqi
# mkdir -p Haqi
# scp -r root@server.240:/opt/haqi_install/Haqi/. ./Haqi/

./haqi_install_update.sh
