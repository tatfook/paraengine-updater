#!/bin/bash

rm -f /root/pubscript/update/rsync_assets.log

rsync -avzr --bwlimit=5000 --log-file=/root/pubscript/update/rsync_assets.log --password-file=/root/pubscript/update/update_cdn.secret /data/update61/assetdownload/update/ update.61@2125rsync.ccgslb.com.cn::update.61.com/haqi/assetupdate/

if [[ $?==0 ]]; then
  echo rsync -avzr /var/www/assetdownload/update/  update.61@2125rsync.ccgslb.com.cn::update.61.com/haqi/assetupdate/ succesfully!
else
  echo rsync -avzr /var/www/assetdownload/update/  update.61@2125rsync.ccgslb.com.cn::update.61.com/haqi/assetupdate/ failed!
fi

cat /root/pubscript/update/rsync_assets.log

rm -f /root/pubscript/update/rsync_assets_new.log

rsync -avzrl --exclude="log*.txt" --log-file=/root/pubscript/update/rsync_assets_new.log /data/update61/assetdownload/update/ root@121.14.117.252::update61/assetdownload/update/
#rsync -avzr --bwlimit=5000 --log-file=/root/pubscript/update/rsync_assets_new.log --password-file=/root/pubscript/update/cdn_new.secret /data/update61/assetdownload/update/ update61@upload-cloud.gls.acadn.com::update61/haqi/assetupdate/
#rsync -avzr --bwlimit=5000 --log-file=/root/pubscript/update/rsync_assets_new.log --password-file=/root/pubscript/update/cdn_new.secret /data/update61/assetdownload/update/ update61@csd007.dnion.com::update61/haqi/assetupdate/
if [[ $?==0 ]]; then
  echo rsync -avzr /var/www/assetdownload/update/  update61@upload-cloud.gls.acadn.com::update61/haqi/assetupdate/ succesfully!
else
  echo rsync -avzr /var/www/assetdownload/update/  update61@upload-cloud.gls.acadn.com::update61/haqi/assetupdate/ failed!
fi

cat /root/pubscript/update/rsync_assets_new.log

echo "ParaEngineCDN AssetsFiles deployed to CDN!"
