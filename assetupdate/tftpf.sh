#!/bin/bash

# echo "this is ftptest"

ftp -n <<!
open 192.168.0.228
user ftpasset ftpparaengine
put /var/www/assetdownload/list/ftpsvrlist.txt ftpsvrlist.txt
bye
!

echo "ftplist update ok"
