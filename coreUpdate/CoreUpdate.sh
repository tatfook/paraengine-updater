#!/usr/bin/env bash

# $# is 0
teentag=""
if [ $# -eq 2 ] ; then
  teentag=$1
  t_newver=$2
else
  if [ $# -eq 1 ]; then
    if [ "$1" == "teen" ];then
      teentag=$1
    else
      t_newver=$1
    fi
  fi
fi


rm -f Assets_manifest0.txt
rm -f version.txt

wget -c "http://localhost/assetdownload/list/full.txt" -O ./Assets_manifest0.txt
if [ ! -e "Assets_manifest0.txt" ];then
  echo Assets_manifest0.txt download from svr228 failed!
  exit 1
fi

if [ "$teentag" == "teen" ];then
  wget -c "http://10.27.2.228/coredownload_teen/version.txt" -O ./version.txt
  listfile="Aries_installer_teen.txt"
  uploadurl="http://10.27.2.228/cgi-bin/upload_teen.sh"
  updatelist="coreupdate_teen.list"
  needlist="core_need_teen.list"
  ftplist="ftpcorelist_teen.txt"
  ftpnew_dir="ftpnew_coredir_teen.txt"
  ftpold_dir="ftpold_coredir_teen.txt"
else
  wget -c "http://localhost/coredownload/version.txt" -O ./version.txt
  listfile="Aries_installer_v1.txt"
  uploadurl="http://10.27.2.228/cgi-bin/upload2.sh"
  updatelist="coreupdate.list"
  needlist="core_need.list"
  ftplist="ftpcorelist.txt"
  ftpnew_dir="ftpnew_coredir.txt"
  ftpold_dir="ftpold_coredir.txt"
fi

sleep 2

rm -f $needlist $updatelist $ftplist $ftpnew_dir $ftpold_dir

testver=`sed -n '/# Core ParaEngine SDK Files Here/,/# Post setup/p'  ParaEngineSDK/$listfile |sed -e 's/^[\t ]*//g' -e '/^[#;]/d' -e '/^[[:space:]]*$/d'  -e 's/\\/\\\\/g' -e 's/\$/\\$/g' | grep "main[0-9]\+.pkg"`

if [ -z "$testver" ];then
  test_miniver=`cat version.txt | sed -n '/<UpdateVersion>/,/<\/UpdateVersion/p' |grep -v Version | awk -F"." '{printf("%s",$3)}'`
  newver=`cat version.txt | sed -n '/<UpdateVersion>/,/<\/UpdateVersion/p' |grep -v Version | awk -F"." '{printf("%s.%s.%d",$1,$2,$3+1)}'`
else
  newver=`cat version.txt | sed -n '/<UpdateVersion>/,/<\/UpdateVersion/p' |grep -v Version | awk -F"." '{printf("%s.%s.%d",$1,$2,$3+1)}'`
fi

if [ -z "$t_newver" ];then
  echo "ver=$newver" >  version.txt
else
  echo "ver=$t_newver" >  version.txt
fi

./generate_corelist.sh $teentag

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
  testfound=`find ./ParaEngineSDK/$tdir -maxdepth 1 -iname $basefln`
  if [[ -z "$testfound" && "$basefln" != "Assets_manifest0.txt" ]];then
    echo "$fln not found in ParaEngineSDK! Check pc241's AB directory again !"
    exit 1
  fi
done < $needlist

rm -f ./tftpcore.sh
./generate_coreftp.sh $teentag

if [ -e "tftpcore.sh" ];then
  /bin/bash tftpcore.sh
  if [ $? -eq 0 ];then
    echo upload core files to svr228 successed!
  else
    exit 1
  fi
fi

./upload2.sh


rm upload_core.htm -f
rm Assets_manifest0.txt -f

