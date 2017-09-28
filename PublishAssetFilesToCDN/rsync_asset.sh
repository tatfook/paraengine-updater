#!/bin/bash

rm -f /usr/local/script/update/rsync_assets.log

rsync -avzr --bwlimit=5000 --log-file=/usr/local/script/update/rsync_assets.log --password-file=/usr/local/script/update/teen213.passwd /var/www/assetdownload/update/ update_haqi@121.14.117.252::update61/assetdownload/update/
#rsync -avzr --bwlimit=5000 --log-file=/usr/local/script/update/rsync_assets.log --password-file=/usr/local/script/update/teen213.passwd /var/www/assetdownload/update/ update_haqi@183.60.209.140::update61/assetdownload/update/

#rsync -avzr --bwlimit=5000 --log-file=/usr/local/script/update/rsync_assets.log --password-file=/usr/local/script/update/update_cdn.secret /var/www/assetdownload/update/ update.61@2125rsync.ccgslb.com.cn::update.61.com/haqi/assetupdate/
if [[ $?==0 ]]; then
  echo rsync -avzr /var/www/assetdownload/update/  update.61@2125rsync.ccgslb.com.cn::update.61.com/haqi/assetupdate/ succesfully!
else
  echo rsync -avzr /var/www/assetdownload/update/  update.61@2125rsync.ccgslb.com.cn::update.61.com/haqi/assetupdate/ failed!
fi

#cat /usr/local/script/update/rsync_assets.log|grep -v deleting|sed -n '/building file list/,/total size/p'|sed '/sent.*received/d' |sed '/total size/d'|grep "\.p\|\.z"|awk -F" " '{printf("http://update.61.com/haqi/assetupdate/%s\n",$5)}' > rep_cdn_assets.txt
#tail -n2 /usr/local/script/update/rsync_assets.log >> rep_cdn_assets.txt
#sleep 1
#./EmailtoCDN.sh  rep_cdn_assets.txt

echo "ParaEngine AssetsFiles deployed to CDN!"
