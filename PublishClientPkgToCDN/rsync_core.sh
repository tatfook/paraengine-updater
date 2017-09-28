#!/bin/bash

rm rsync_core.log -f

rsync -avzr --bwlimit=10000 --log-file=/usr/local/script/update/rsync_core.log --password-file=/usr/local/script/update/tatfook.passwd /var/www/coredownload/ update_haqi@121.14.117.252::update61/coredownload/

# other server??
#rsync -avzr --bwlimit=10000 --log-file=/usr/local/script/update/rsync_core.log --password-file=/usr/local/script/update/tatfook.passwd /var/www/coredownload/ update_haqi@121.14.117.236::update61/coredownload/
#rsync -avzr --bwlimit=5000 --log-file=/usr/local/script/update/rsync_core.log --password-file=/usr/local/script/update/teen213.passwd /var/www/coredownload/ update_haqi@114.80.98.36::update61/coredownload/
#rsync -avzr --bwlimit=5000 --log-file=/usr/local/script/update/rsync_core.log --password-file=/usr/local/script/update/teen213.passwd /var/www/coredownload/ update_haqi@183.60.209.140::update61/coredownload/
#rsync -avzr --bwlimit=5000 --log-file=/usr/local/script/update/rsync_core.log --password-file=/usr/local/script/update/update_cdn.secret /var/www/coredownload/ update.61@2125rsync.ccgslb.com.cn::update.61.com/haqi/coreupdate/coredownload/

if [[ $? == 0 ]]; then
  echo rsync -avzr /var/www/coredownload/ update.haqi@ccrsync.chinacache.chinacache.net::update.haqi/coreupdate/coredownload/ succesfully!
else
  echo rsync -avzr /var/www/coredownload/ update.haqi@ccrsync.chinacache.chinacache.net::update.haqi/coreupdate/coredownload/ failed!
fi

#cat /usr/local/script/update/rsync_core.log|grep -v deleting|sed -n '/version.txt/,/total size/p'|sed '/sent.*received/d' |sed '/total size/d'|grep "\.p\|\.txt"|awk -F" " '{printf("http://update.61.com/haqi/coreupdate/coredownload/%s\n",$5)}'> rep_cdn.txt
#tail -n6 /usr/local/script/update/rsync_core.log |head -n2 >> rep_cdn.txt
#sleep 1
#./EmailtoCDN.sh rep_cdn.txt

echo "ParaEngine CoreUpdated Files deployed to CDN!"
