#!/bin/bash

# rm /root/pubscript/update/rsync_core.log -f
#rsync -avzr --bwlimit=10000 --log-file=/root/pubscript/update/rsync_core.log --password-file=/root/pubscript/update/update_cdn.secret /data/update61/coredownload/ update.61@2125rsync.ccgslb.com.cn::update.61.com/haqi/coreupdate/coredownload/
#if [[ $?==0 ]]; then
# echo rsync -avzr coredownload/ update.haqi@ccrsync.chinacache.chinacache.net::update.haqi/coreupdate/coredownload/ succesfully!
#else
# echo rsync -avzr coredownload/ update.haqi@ccrsync.chinacache.chinacache.net::update.haqi/coreupdate/coredownload/ failed!
#fi
#cat /root/pubscript/update/rsync_core.log

#cat /usr/local/script/update/rsync_core.log|grep -v deleting|sed -n '/version.txt/,/total size/p'|sed '/sent.*received/d' |sed '/total size/d'|grep "\.p\|\.txt"|awk -F" " '{printf("http://update.61.com/haqi/coreupdate/coredownload/%s\n",$5)}'> rep_cdn.txt
#tail -n6 /usr/local/script/update/rsync_core.log |head -n2 >> rep_cdn.txt
#sleep 1
#./EmailtoCDN.sh rep_cdn.txt

rm /root/pubscript/update/rsync_core_new.log -f

rsync -avzr --bwlimit=10000 --log-file=/root/pubscript/update/rsync_core_new.log --password-file=/root/pubscript/update/cdn_new.secret /data/update61/coredownload/ update61@newupload.dnion.com::update61/haqi/coreupdate/coredownload/
#rsync -avzr --bwlimit=10000 --log-file=/root/pubscript/update/rsync_core_new.log --password-file=/root/pubscript/update/cdn_new.secret /data/update61/coredownload/ update61@csd007.dnion.com::update61/haqi/coreupdate/coredownload/

if [[ $?==0 ]]; then
  echo rsync -avzr coredownload/ update61@newupload.dnion.com::update61/haqi/coreupdate/coredownload/ succesfully!
else
  echo rsync -avzr coredownload/ update61@newupload.dnion.com::update61/haqi/coreupdate/coredownload/ failed!
fi

cat /root/pubscript/update/rsync_core_new.log

echo "ParaEngineCDN CoreUpdated Files deployed to CDN!"
