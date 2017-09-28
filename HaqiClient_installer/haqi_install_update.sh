#!/bin/bash

# This script works as a Haqi client, it upgrade the client folders to get the newest client version, and then generate the newest nsi files to create the newest installer.
# Att: the script works with upgrade mode, so the local ver must not the newest one.

haqidir="./Haqi"
cachelst=$haqidir/installer/Aries/cache_file.txt
SDKdir="/mnt/ParaEngineSDK"

rm -f Assets_manifest0.txt
rm -f version.txt
rm -f new_cache0.txt

wget -c "http://localhost/assetdownload/list/full.txt" -O ./Assets_manifest0.txt
if [ $? -ne 0 ];then
  echo download Assets_manifest0.txt error!
  exit 1
fi

wget -c "http://localhost/coredownload/version.txt" -O ./version.txt
if [ $? -ne 0 ];then
  echo download version.txt error!
  exit 1
fi

rm -f $haqidir/config/config.txt
cp /mnt/ParaEngineSDK/config/config.txt $haqidir/config/.

svn checkout svn://192.168.0.200/script/trunk/installer/Aries /opt/haqi_install/Haqi/installer/Aries --username YDD --password YDDParaEngine

newver=`cat version.txt | sed -n '/<UpdateVersion>/,/<\/UpdateVersion/p' |grep -v Version | awk -F"." '{printf("%s.%s.%d",$1,$2,$3)}'`

curver=`cat $haqidir/version.txt| cut -d= -f2|awk -F"." '{printf("%s.%s.%d",$1,$2,$3)}'`

rm $haqidir/temp/assetszip/* -f
rm $haqidir/temp/cache/* -f

#check if current version on local is newest, if it's newest, then cannot generate installer file.
if [ "$curver" == "$newver"  ];then
  echo "Current ver. $curver is the newest!"
  curver0=`echo $curver|awk -F"." '{printf("%s.%s.%d",$1,$2,$3-1)}'`
  curver=$curver0
  echo "Now USE $curver patch list to update & make installer  again!"
  # exit 1
fi

# get the newest cache files from the newest Assets_manifest0.txt
while read filenm
do
  file0=`echo $filenm|cut -d, -f1|sed -e 's/.z$//' -e 's/.p$//'`
  tempurlfile=`grep "$file0" Assets_manifest0.txt|awk -F"," '{printf("%s",$1)}'`
  tempzipfile=`basename $tempurlfile`
  tempfile=`echo $tempzipfile|sed -e 's/.z$//'`
  cachefile=`grep "$tempurlfile" Assets_manifest0.txt|awk -F"," '{printf("%s%s",$2,$3)}'`
  wget -q -c "http://localhost/assetdownload/update/$tempurlfile" -O $haqidir/temp/assetszip/$tempzipfile

  testz=`echo "$tempzipfile"| grep -E "\.z$"`
  if [ ! -z "$testz" ];then
    unzip -q -x $haqidir/temp/assetszip/$tempzipfile -d $haqidir/temp/assetszip
  else
    tempfile=`echo $tempzipfile|sed -e 's/.p$//'`
    cp $haqidir/temp/assetszip/$tempzipfile $haqidir/temp/assetszip/$tempfile -f
  fi
  if [ ! -z "$cachefile" ];then
    cp $haqidir/temp/assetszip/$tempfile $haqidir/temp/cache/$cachefile
  fi
  rm $haqidir/temp/assetszip/* -f
  if [ $? -ne 0 ];then
    echo download $tempfile error!
    exit 1
  fi
done < $cachelst

echo "The newest cache files created successful!"

# get the patch list of local ver.
rm -f patch*.txt
wget -c "http://localhost/coredownload/$newver/list/patch_$curver.txt" -O ./patch0.txt
if [ $? -ne 0 ];then
  echo download patch_$curver.txt error!
  wget -c "http://localhost/coredownload/$newver/list/full.txt" -O ./patch0.txt
  if [ $? -ne 0 ];then
    echo download $newver full.txt error!
    exit 1
  fi
fi


cp patch0.txt  patch.txt
rm -rf "$haqidir/Update/default/"
mkdir -p "$haqidir/Update/default/$newver"

# download the patch files, unzip them, and then update client files to newest ver.
while read filenm
do
  downloadfile=`echo $filenm | awk -F",0," '{print $1}'`
  zipfilenm=`echo $filenm |cut -d, -f1`
  orgfile=`echo $zipfilenm|sed -e 's/.p$//'`
  testdir=`echo $zipfilenm|grep "/"`
  if [ ! -z "$testdir"  ];then
    newdir=`echo $zipfilenm|cut -d"/" -f1`
    mkdir -p "$haqidir/Update/default/$newver/$newdir"
  fi
  wget -c "http://localhost/coredownload/$newver/update/$zipfilenm" -O "$haqidir/Update/default/$newver/$zipfilenm"
  if [ $? -ne 0 ];then
    echo download $zipfilenm error!
    exit 1
  fi
  gunzip -c $haqidir/Update/default/$newver/$zipfilenm > $haqidir/Update/default/$newver/$orgfile
  if [ "$orgfile" == "deletefile.list"  ];then
    rm $haqidir/deletefile.list.old -f
    mv $haqidir/deletefile.list $haqidir/deletefile.list.old
  fi
  cp $haqidir/Update/default/$newver/$orgfile $haqidir/$orgfile -f
done < patch.txt

while read filenm
do
  filenm0=`echo $filenm|cut -d, -f1`
  rm $haqidir/$filenm0 -f
done < $haqidir/deletefile.list
echo The files on Deletefile.list are deleted!

# generate the newest nsi file
sed -e s/$curver/$newver/g $haqidir/Haqi_installer.nsi > $haqidir/Haqi_installer0.nsi

Rnewmainpkg=`find $haqidir -regex "$haqidir/main[0-9]+.pkg"|awk -F"$haqidir/" '{print $2}'`
nsimainpkg=""
for mainpkgfln in ${Rnewmainpkg[@]}
do
  echo $mainpkgfln
  nsimainpkg=$nsimainpkg"\tFile \/oname=$mainpkgfln $mainpkgfln\n"
done

# check new files in patch list, and insert them into nsi file
# Att: Now, only files in root can be added correctly!

newfile=(`cat patch.txt |grep -v main.*.pkg|cut -d, -f1|sed -e 's/\.p$//g'`)
nsinewfile=""
# only add file to root directory
for newfln in ${newfile[@]}
do
  testnewfln=`grep -i "$newfln" $haqidir/Haqi_installer0.nsi`
  if [ -z "$testnewfln" ];then
    testdir=`echo $newfln| grep "/"`
    nsinewfile="\tFile $newfln \n"
    if [ -z "$testdir" ];then
      sed '/version.txt/a\'"$nsinewfile" $haqidir/Haqi_installer0.nsi  > $haqidir/Haqi_installer1.nsi
      cp $haqidir/Haqi_installer1.nsi $haqidir/Haqi_installer0.nsi
    fi
  fi

done

if [ ! -z "$nsimainpkg" ];then
  grep -E -v main[0-9]+.pkg $haqidir/Haqi_installer0.nsi|sed '/main.pkg/a\'"$nsimainpkg" > $haqidir/Haqi_installer1.nsi
  rm $haqidir/Haqi_installer.nsi -f
  rm $haqidir/Haqi_installer0.nsi -f
  mv $haqidir/Haqi_installer1.nsi $haqidir/Haqi_installer.nsi
else
  rm $haqidir/Haqi_installer.nsi -f
  mv $haqidir/Haqi_installer0.nsi $haqidir/Haqi_installer.nsi
fi

echo "Haqi_installer.nsi created successful!"


sed -e s/$curver/$newver/g $haqidir/Aries_web_installer_v1.nsi > $haqidir/Aries_web_installer_v0.nsi
rm $haqidir/Aries_web_installer_v1.nsi -f
mv $haqidir/Aries_web_installer_v0.nsi $haqidir/Aries_web_installer_v1.nsi
echo "Aries_web_installer_v0.nsi created successful!"

rm $haqidir/config/Aries.commands.xml -f
rm $haqidir/config/TaoMee.GameClient.config.xml -f
rm $haqidir/installer/Aries/Assets_manifest0.txt -f

svn checkout svn://192.168.0.200/script/trunk/script ./script.svn --username YDD --password YDDParaEngine
svn checkout svn://192.168.0.200/script/trunk/config ./config.svn --username YDD --password YDDParaEngine
cp ./config.svn/config.safemode.txt  $haqidir/config/. -f
cp ./config.svn/Aries.commands.xml  $haqidir/config/. -f
cp ./config.svn/TaoMee.GameClient.config.xml  $haqidir/config/. -f

cp Assets_manifest0.txt  $haqidir/installer/Aries/. -f

rm Assets_manifest0.txt -f
rm patch.txt -f

rm $haqidir/Release/*.* -f

# run makensis to generate the windows installer
/usr/local/nsis/bin/makensis $haqidir/Haqi_installer.nsi
if [ $? -ne 0 ];then
  echo Haqi_0.$newver_installer.exe created failed!
  exit 1
fi

/usr/local/nsis/bin/makensis $haqidir/Aries_web_installer_v1.nsi
if [ $? -ne 0 ];then
  echo HaqiWebInstaller_$newver created failed!
  exit 1
fi



# from server 228 rsync config
# [haqi_inst]
# path= /var/www/assetdownload/installer/web
cp -a ./Haqi/Release/*.exe /var/www/assetdownload/installer/web/
if [ $? -ne 0 ];then
  echo publish Haqi Installer to svr228 failed!
  exit 1
fi

# rsync core update files, assets update files, installer files from LAN publish svr228 to WAN publish svr134
# (opt) for backup
./rsync_svr134.sh
