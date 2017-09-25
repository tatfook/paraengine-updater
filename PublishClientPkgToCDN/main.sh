#! /bin/sh
#
# main.sh
# Copyright (C) 2017 zdw <zdw@zdw-mint>
#
# Distributed under terms of the MIT license.
#
#
# run on server.25, linux
#
#


./svr_auto.sh "192.168.0.228" "paraengine" "/usr/local/script/update/rsync_core.sh"

echo "-----WAN tafoo svr252 deploy to CDN .... "
./WanDeployCDN.sh "kids" > cdn_core_kids.txt

sleep 1
cat cdn_core_kids.txt

testcdn=`cat /usr/local/script/hudson/WAN/cdn_core_kids.txt|grep "fail\|timed out"`
if [ -z "$testcdn" ];then
  echo "done"
else
  echo "failed!"
  exit -1;
fi
