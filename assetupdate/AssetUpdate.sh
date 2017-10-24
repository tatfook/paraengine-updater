#!/bin/bash

set -x

svn checkout --username YDD --password YDDParaEngine svn://10.27.2.200/script/trunk/packages ./packages
svn update ./packages

cp -af "./packages/redist/_assetmanifest.ftp.uploader.txt" assetmanifest.txt
conf_file="assetmanifest.txt"


grep -v "^--" "$conf_file" | grep -v "\[search*" | grep -v "\[exclude*" |tr -s '\r\n' '\n' |sed '/^$/d' | sed -e 's/[\t ]*$//g' > all_tmp0.list
grep "\[search\]" "$conf_file" | grep -v "^--" | sed -e 's/\[search\]//g'| sed -e 's/[\t ]*$//g' > search_tmp0.list
grep "\[search1\]" "$conf_file" | grep -v "^--" | sed -e 's/\[search1\]//g'| sed -e 's/[\t ]*$//g' > search1_tmp0.list
grep "\[search3\]" "$conf_file" | grep -v "^--" | sed -e 's/\[search3\]//g'| sed -e 's/[\t ]*$//g' > search3_tmp0.list
grep "\[exclude\]" "$conf_file" | grep -v "^--" | sed -e 's/\[exclude\]//g'| sed -e 's/[\t ]*$//g' > exclude_tmp0.list
grep "\[exclude1\]" "$conf_file" | grep -v "^--" | sed -e 's/\[exclude1\]//g'| sed -e 's/[\t ]*$//g' > exclude1_tmp0.list


rm -f all_tmp1.list
rm -f search_tmp1.list
rm -f exclude_tmp1.list

while read xx0
do
  spath=`dirname $xx0`/
  sname=`basename $xx0| tr -s '\r\n' '\n'`
  if [ -d "ParaEngineSDK/$spath" ];then
    find "ParaEngineSDK/$spath" -iname "$sname" -printf "-r-xr-Sr-x 1 root root %s %TY-%Tm-%Td %TH:%TM %p\n" |grep -v ".svn" >> all_tmp1.list
  fi
done < all_tmp0.list

while read xx
do
  spath=`dirname $xx`/
  sname=`basename $xx| tr -s '\r\n' '\n'`
  if [ -d "ParaEngineSDK/$spath" ];then
    find "ParaEngineSDK/$spath" -iname "$sname" -printf "-r-xr-Sr-x 1 root root %s %TY-%Tm-%Td %TH:%TM %p\n" |grep -v ".svn" >> search_tmp1.list
  fi
done < search_tmp0.list

while read xx
do
  spath=`dirname $xx`/
  sname=`basename $xx| tr -s '\r\n' '\n'`
  if [ -d "ParaEngineSDK/$spath" ];then
    find "ParaEngineSDK/$spath" -maxdepth 1 -iname "$sname" -printf "-r-xr-Sr-x 1 root root %s %TY-%Tm-%Td %TH:%TM %p\n" |grep -v ".svn" >> search_tmp1.list
  fi
done < search1_tmp0.list

while read xx
do
  spath=`dirname $xx`/
  sname=`basename $xx| tr -s '\r\n' '\n'`
  if [ -d "ParaEngineSDK/$spath" ];then
    find "ParaEngineSDK/$spath" -maxdepth 3 -iname "$sname" -printf "-r-xr-Sr-x 1 root root %s %TY-%Tm-%Td %TH:%TM %p\n" |grep -v ".svn" >> search_tmp1.list
  fi
done < search3_tmp0.list

echo "" > exclude_tmp1.list
while read xx
do
  spath=`dirname $xx`/
  sname=`basename $xx| tr -s '\r\n' '\n'`
  if [ -d "ParaEngineSDK/$spath" ];then
    find "ParaEngineSDK/$spath" -iname "$sname" -printf "-r-xr-Sr-x 1 root root %s %TY-%Tm-%Td %TH:%TM %p\n" |grep -v ".svn" >> exclude_tmp1.list
  fi
done < exclude_tmp0.list

while read xx
do
  spath=`dirname $xx`/
  sname=`basename $xx| tr -s '\r\n' '\n'`
  if [ -d "ParaEngineSDK/$spath" ];then
    find "ParaEngineSDK/$spath" -maxdepth 1 -iname "$sname" -printf "-r-xr-Sr-x 1 root root %s %TY-%Tm-%Td %TH:%TM %p\n" |grep -v ".svn" >> exclude_tmp1.list
  fi
done < exclude1_tmp0.list



sort all_tmp1.list search_tmp1.list | uniq -u | grep -v -i "\.bak"> all_tmp2.list
sort all_tmp2.list exclude_tmp1.list | uniq -d > same_tmp.list
sort all_tmp2.list same_tmp.list | uniq -u > ftp_all.list


./generate_new_name.pl |grep -v ".svn" > ftp_new_name.txt


wget "http://localhost/assetdownload/list/ftpsvrlist0.txt" -O ./ftpsvrlist0.txt


sort ./ftpsvrlist0.txt |uniq > ftpsvr_sort.txt
sort ftp_new_name.txt | uniq > ftpnewname_sort.txt
sort ftpnewname_sort.txt ./ftpsvr_sort.txt |uniq -di > ab.txt
sort ftpnewname_sort.txt ab.txt |uniq -ui | grep -v " " > need_upload.txt



testChflnm=`cat need_upload.txt | sed -e 's/\(.*\)\/\(.*\)/\2/'| grep -E -v ^[0-9a-zA-Z_\-\/\.\(\)]\+\\.`
if [ ! -z "$testChflnm" ];then
  echo "Chinese Filename exist! $testChflnm"
  cat need_upload.txt
  exit 1
fi


rm -f ./tftpasset.sh
./generate_ftpscript.sh
if [ -e "tftpasset.sh" ];then
  /bin/bash tftpasset.sh
fi


sudo chown www-data:www-data /var/www/* -R



./upload_asset2.sh

