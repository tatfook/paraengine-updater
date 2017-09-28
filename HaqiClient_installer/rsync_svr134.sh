#!/bin/bash

cp ./userdownload.list /var/www/assetdownload/update/userdownload.list

rsync -avzr --delete-excluded /var/www/assetdownload/ root@114.80.99.134::pubbak/assetdownload/

rsync -avzr --delete-excluded /var/www/coredownload/ root@114.80.99.134::pubbak/coredownload/

rsync -avzr --delete-excluded /home/ftpuser1/. root@114.80.99.134::homeupload/
rsync -avzr --delete-excluded /home/ftpasset/. root@114.80.99.134::homeupload/

rsync -avzr --delete-excluded /var/www/asset/ root@114.80.99.134::pubbak/asset/

rsync -avzr --delete-excluded /var/www/prog/ root@114.80.99.134::pubbak/prog/

echo "ParaEngine Client update files rsync to WAN publish svr 114.80.99.134 sucessed!"

