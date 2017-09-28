#!/bin/bash

cp /usr/local/script/download_stat/userdownload.list /var/www/assetdownload/update/userdownload.list

rsync -avzr --delete-excluded /var/www/assetdownload/ root@114.80.99.134::pubbak/assetdownload/

rsync -avzr --delete-excluded /var/www/coredownload/ root@114.80.99.134::pubbak/coredownload/

rsync -avzr --delete-excluded /home/upload/ root@114.80.99.134::homeupload/

rsync -avzr --delete-excluded /var/www/asset/ root@114.80.99.134::pubbak/asset/

rsync -avzr --delete-excluded /var/www/prog/ root@114.80.99.134::pubbak/prog/

echo "ParaEngine Client update files rsync to WAN publish svr 114.80.99.134 sucessed!"
#rsync -avz /var/www/coredownload/version.txt root@114.80.99.124::webserver/APICenter/version.php

