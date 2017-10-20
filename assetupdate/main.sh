#!/usr/bin/env bash

# run on server.240, linux
#
#
# prequisite
# 1. ParaEngineSDK -> /mnt/ParaEngineSDK -> server.241 mount

# interact
# 1. svn checkout from svn://10.27.2.200/script/trunk/packages
#    cp  "./packages/redist/_assetmanifest.ftp.uploader.txt" assetmanifest.txt
#
# 2. wget "http://10.27.2.228/assetdownload/list/ftpsvrlist0.txt" -O ./ftpsvrlist0.txt
# 3. wget "http://10.27.2.228/assetdownload/list/ftpsvrlist.txt" -O ./ftpsvrlist.txt
#
# 4. ftp upload to server.228
#    "open 10.27.2.228" >> tftpasset.sh
#    "user ftpasset ftpparaengine" >> tftpasset.sh
#    ftpasset user in 228, root is /home/upload/asset/
#
# 5. ./svr_auto.sh "10.27.2.228" "paraengine" "/usr/local/script/renew_assetlist/chown_varwww.sh"
#    chown www-data:www-data /var/www/* -R
#
# 6. call server.228 /usr/lib/cgi-bin/upload_asset2.sh
#
#    copy from /home/upload/asset and update files in /var/www/assetdownload/* (list & update)
#    fetch /var/www/assetdownload/list/ftpsvrlist.txt back to /home/upload/asset/ftpsvrlist.txt
#
# (opt)7. rsync to 233(for backup)
#    thisday=`date +%Y%m%d`
#    /usr/bin/rsync -avz /var/www/assetdownload/list/full0.txt root@10.27.2.233::assetbak/full0_$thisday.txt
#    /usr/bin/rsync -avz /var/www/assetdownload/list/ftpsvrlist0.txt root@10.27.2.233::assetbak/ftpsvrlist0_$thisday.txt

# prequisite
# 1. ParaEngineSDK -> /mnt/ParaEngineSDK
sudo ln -sf /mnt/ParaEngineSDK ParaEngineSDK

# svn update --username svr233 --password svr233ParaEngine
# from svn://10.27.2.200/hudson_conf/ci_shell/Client/AssetUpdate.sh
./AssetUpdate.sh

