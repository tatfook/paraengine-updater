#!/usr/bin/env bash
#
#

# rsync asset files to CDN

# rsync files to 252
./rsync_asset.sh


# from 252 upload asset to 61 CDN
./WanDeployCDN.sh "assets" > /usr/local/script/hudson/WAN/cdn_assets.txt

sleep 1
testcdn=`cat /usr/local/script/hudson/WAN/cdn_assets.txt|grep "fail\|timed out"`
if [ -z "$testcdn"  ];then
  echo "done"
else
  echo "failed!"
  exit -1;
fi
