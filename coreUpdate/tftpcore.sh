#!/usr/bin/env bash

# echo "this is ftptest"

ftp -n <<!
 open 192.168.0.228
 user ftpuser1 ftpparaengine
 put /var/www/coredownload/list/ftpcorelist.txt ftpcorelist.txt
 bye
 ! 

echo "ftplist update ok"
