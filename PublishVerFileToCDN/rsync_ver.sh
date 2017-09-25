#!/usr/bin/env bash

rsync -avz --password-file=/usr/local/script/update/tatfook.passwd /var/www/coredownload/version.txt update_haqi@121.14.117.236::webserver/PostLog/version.php

rsync -avz --password-file=/usr/local/script/update/teen213.passwd /var/www/coredownload/version.txt update_haqi@115.29.230.154::webserver/tmver/version.php

rsync -avzr --bwlimit=10000 --log-file=/usr/local/script/update/rsync_list_124.log --delete-excluded --password-file=/usr/local/script/update/tatfook.passwd /var/www/coredownload/ update_haqi@121.14.117.236::webserver/PostLog/coreupdate/coredownload/

echo "ParaEngine Kids Ver Files deployed to CDN!"
