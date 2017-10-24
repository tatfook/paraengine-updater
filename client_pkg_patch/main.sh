#!/usr/bin/env bash

# run in server.25, linux

# need npl env and main&paraenginesdk packages

# steps
# 1. svn update svn://svn.paraengine.com/script/trunk
# YDD:YDDParaEngine
#
# 2. call ./get_pkg_patch.sh 17798
# server.25:/var/lib/hudson/jobs/client_pkg_patch/get_pkg_patch.sh
#
#
# result
# nothing left
# 1. gen main.pkg and copy to /mnt/??

# svn checkout code
# it'll auto update repo
svn checkout --username YDD --password YDDParaEngine --depth infinity \
  svn://svn.paraengine.com/script/trunk paraengine.svn
svn update paraengine.svn

ln -sf /opt/NPLRuntime/ParaWorld/bin64/ParaEngineServer ParaEngineServer
ln -sf /mnt/ParaEngineSDK/config config
ln -sf ./paraengine.svn/packages packages
ln -sf ./paraengine.svn/script script

./get_pkg_patch.sh 17798
