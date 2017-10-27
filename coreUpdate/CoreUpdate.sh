#!/usr/bin/env bash

if [ $# -eq 1 ]; then
  t_newver=$1
fi


rm upload_core.htm -f




rm -f Assets_manifest0.txt
wget -c "http://localhost/assetdownload/list/full.txt" -O ./Assets_manifest0.txt
if [ ! -e "Assets_manifest0.txt" ];then
  echo Assets_manifest0.txt download from svr228 failed!
  exit 1
fi


rm -f version.txt
wget -c "http://localhost/coredownload/version.txt" -O ./version.txt

updatelist="coreupdate.list"
ftplist="ftpcorelist.txt"
ftpnew_dir="ftpnew_coredir.txt"
ftpold_dir="ftpold_coredir.txt"


rm -f $updatelist $ftplist $ftpnew_dir $ftpold_dir



needlist="core_need.list"
listfile="Aries_installer_v1.txt"

newver=`cat version.txt | sed -n '/<UpdateVersion>/,/<\/UpdateVersion/p' |grep -v Version | awk -F"." '{printf("%s.%s.%d",$1,$2,$3+1)}'`

if [ -z "$t_newver" ];then
  echo "ver=$newver" >  version.txt
else
  echo "ver=$t_newver" >  version.txt
fi


./generate_corelist.sh

if [ ! -e "$needlist" ];then
  echo CoreUpdate list generate failed! check generate_corelist.sh!
  exit 1
fi


while read line
do
  fln=`echo $line|cut -d, -f1`
  testdir=`echo $fln|grep "/"`
  tdir=""
  if [ ! -z "$testdir" ];then
    tdir=`dirname $fln`/
  fi
  basefln=`basename $fln`
  # FIXME database/characters should be Database/characters
  testfound=`find ./ParaEngineSDK/$tdir -maxdepth 1 -iname $basefln`
  if [[ -z "$testfound" && "$basefln" != "Assets_manifest0.txt" ]];then
    echo "$fln not found in ParaEngineSDK! Check pc241's AB directory again !"
    exit 1
  fi
done < $needlist



rm -f ./tftpcore.sh
./generate_coreftp.sh

if [ -e "tftpcore.sh" ];then
  /bin/bash tftpcore.sh
  if [ $? -eq 0 ];then
    echo upload core files to svr228 successed!
  else
    exit 1
  fi
fi


./upload2.sh

