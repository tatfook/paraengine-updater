#!/usr/bin/env bash

# usage:
#    ./CoreUpdate.sh ver

# teen version is obesolete
teentag=""
if [ $# -eq 2 ]; then
    teentag=$1
    t_newver=$2
else
    if [ $# -eq 1 ]; then
        if [ "$1" == "teen" ]; then
            teentag=$1
        else
            t_newver=$1
        fi
    fi
fi
# t_newver store the ver

cd /opt/hudson_conf/ci_shell/Client
rm -f Assets_manifest0.txt
rm -f version.txt

# download file from 228 apache server
# 228 path: /var/www/assetdownload/list/full.txt
wget -c "http://192.168.0.228/assetdownload/list/full.txt" -O ./Assets_manifest0.txt

# no teentag
if [ "$teentag" == "teen" ]; then
    wget -c "http://192.168.0.228/coredownload_teen/version.txt" -O ./version.txt
    listfile="Aries_installer_teen.txt"
    uploadurl="http://192.168.0.228/cgi-bin/upload_teen.sh"
    updatelist="coreupdate_teen.list"
    needlist="core_need_teen.list"
    ftplist="ftpcorelist_teen.txt"
    ftpnew_dir="ftpnew_coredir_teen.txt"
    ftpold_dir="ftpold_coredir_teen.txt"
else
    # download 228 : /var/www/coredownload/version.txt
    wget -c "http://192.168.0.228/coredownload/version.txt" -O ./version.txt
    listfile="Aries_installer_v1.txt"
    uploadurl="http://192.168.0.228/cgi-bin/upload2.sh"
    updatelist="coreupdate.list"
    needlist="core_need.list"
    ftplist="ftpcorelist.txt"
    ftpnew_dir="ftpnew_coredir.txt"
    ftpold_dir="ftpold_coredir.txt"
fi

# ??
sleep 2
rm -f $needlist
rm -f $updatelist
rm -f $ftplist
rm -f $ftpnew_dir
rm -f $ftpold_dir

if [ ! -e "Assets_manifest0.txt" ]; then
    echo Assets_manifest0.txt download from svr228 failed!
    exit 1
fi

# ParaEngineSDK links to /mnt/ParaEngineSDK, mount from //192.168.0.241/ParaEngineSDK
# listfile => Aries_installer_teen.txt
# grep mainxxx.pkg
# no result now, there's no # Core ParaEngine line!!!! in $listfile!!! joke
testver=$(sed -n '/# Core ParaEngine SDK Files Here/,/# Post setup/p' ParaEngineSDK/$listfile | sed -e 's/^[\t ]*//g' -e '/^[#;]/d' -e '/^[[:space:]]*$/d' -e 's/\\/\\\\/g' -e 's/\$/\\$/g' | grep "main[0-9]\+.pkg")

# transform  <UpdateVersion>ver</UpdateVersion>  to version=ver format
if [ -z "$testver" ]; then
    test_miniver=$(cat version.txt | sed -n '/<UpdateVersion>/,/<\/UpdateVersion/p' | grep -v Version | awk -F"." '{printf("%s",$3)}')
    # minor version+1, 0.7.330 => 0.7.331
    newver=$(cat version.txt | sed -n '/<UpdateVersion>/,/<\/UpdateVersion/p' | grep -v Version | awk -F"." '{printf("%s.%s.%d",$1,$2,$3+1)}')
else
    newver=$(cat version.txt | sed -n '/<UpdateVersion>/,/<\/UpdateVersion/p' | grep -v Version | awk -F"." '{printf("%s.%s.%d",$1,$2,$3+1)}')
fi

# t_newver is $1
if [ -z "$t_newver" ]; then
    echo "ver=$newver" >version.txt
else
    echo "ver=$t_newver" >version.txt
fi

# no teentag here
# call generate_corelist
# gerenate core_need.list
./generate_corelist.sh $teentag

if [ ! -e "$needlist" ]; then
    echo CoreUpdate list generate failed! check generate_corelist.sh!
    exit 1
fi

# e.g.
# autoupdater.dll,autoupdater.dll._P_E_0
# updateversion.exe,updateversion.exe._P_E_0
# copyright.txt,copyright.txt._P_E_0
# readme.txt,readme.txt._P_E_0
# version.txt,version.txt._P_E_0
# installer/Aries/Assets_manifest0.txt,assets_manifest.txt._P_E_0
# config/config.txt,config/config.txt._P_E_0
# installer/Aries/bootstrapper.xml,config/bootstrapper.xml._P_E_0
while read line; do
    # fln means filename
    fln=$(echo $line | cut -d, -f1)
    testdir=$(echo $fln | grep "/")

    tdir=""
    # path has /
    if [ ! -z "$testdir" ]; then
        tdir=$(dirname $fln)/
    fi
    basefln=$(basename $fln)

    testfound=$(find ./ParaEngineSDK/$tdir -maxdepth 1 -iname $basefln)
    # if not file not found!
    if [[ -z "$testfound" && "$basefln" != "Assets_manifest0.txt" ]]; then
        echo "$fln not found in ParaEngineSDK! Check pc241's AB directory again !"
        exit 1
    fi
done <$needlist

# generate coreftp
# upload to 228 server
rm -f ./tftpcore.sh
./generate_coreftp.sh $teentag

if [ -e "tftpcore.sh" ]; then
    /bin/bash tftpcore.sh
    if [ $? -eq 0 ]; then
        echo upload core files to svr228 successed!
    else
        exit 1
    fi
fi

# uploadurl="http://192.168.0.228/cgi-bin/upload2.sh"
# 228 /usr/lib/cgi-bin/upload2.sh
# call bash script in 228
wget -c "$uploadurl" -O ./upload_core.htm
# paint process
cat upload_core.htm | grep -v "Processing"

# clean things
rm upload_core.htm -f
rm Assets_manifest0.txt -f
