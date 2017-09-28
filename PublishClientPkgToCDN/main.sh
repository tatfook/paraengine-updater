#! /bin/sh
#
#
# run on server.25, linux
#


# rsync /var/www/coredownload to 252
./rsync_core.sh

echo "use server 252 deploy to CDN"
./WanDeployCDN.sh "kids" > cdn_core_kids.txt

sleep 1
cat cdn_core_kids.txt

testcdn=`cat cdn_core_kids.txt|grep "fail\|timed out"`
if [ -z "$testcdn" ];then
  echo "done"
else
  echo "failed!"
  exit -1;
fi
