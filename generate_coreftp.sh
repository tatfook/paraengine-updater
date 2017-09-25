#!/bin/bash

teentag=""
if [ $# -eq 1 ]; then
    teentag=$1
fi

cd /opt/hudson_conf/ci_shell/Client

if [ "$teentag" == "teen" ]; then
    needlist="core_need_teen.list"
    ftplist="ftpcorelist_teen.txt"
    ftpnew_dir="ftpnew_coredir_teen.txt"
    ftpold_dir="ftpold_coredir_teen.txt"
    ftpuser="ftpteen"
    # get current ftp files list on LAN publish svr: svr228
    rm -f $ftplist
    wget "http://192.168.0.228/coredownload_teen/list/ftpcorelist.txt" -O ./$ftplist
else
    needlist="core_need.list"
    ftplist="ftpcorelist.txt"
    ftpnew_dir="ftpnew_coredir.txt"
    ftpold_dir="ftpold_coredir.txt"
    ftpuser="ftpuser1"
    # get current ftp files list on LAN publish svr: svr228
    rm -f $ftplist
    # 228  /var/www/coredownload/list/ftpcorelist.txt
    wget "http://192.168.0.228/coredownload/list/ftpcorelist.txt" -O ./$ftplist
fi

# core_need.list
# e.g.
# config/config.txt,config/config.txt._P_E_0
# installer/Aries/bootstrapper.xml,config/bootstrapper.xml._P_E_0
# installer/Aries/bootstrapper_safemode.xml,config/bootstrapper_safemode.xml._P_E_0
# config/TaoMee.GameClient.config.xml,config/gameclient.config.xml._P_E_0
# get directory names from core update files
#
# why not dirname?
#
cut -d, -f2 $needlist | grep "/" | sed -e 's/\(.*\)\/\(.*\)/\1/' | sort | uniq >$ftpnew_dir

# generate FTP scripts to tftpcore.sh
rm -f tftpcore.sh
echo "#!/bin/bash" >tftpcore.sh
echo "ftp -n << !" >>tftpcore.sh
echo "open 192.168.0.228" >>tftpcore.sh
echo "user $ftpuser ftpparaengine" >>tftpcore.sh

# delete all files & dir on core ftp server
echo "delete $ftplist" >>tftpcore.sh

# get current ftp folder names on LAN publish svr from ftpcorelist.txt
rm -f $ftpold_dir
grep "/" $ftplist | sed -e 's/\(.*\)\/\(.*\)/\1/' | sort | uniq >$ftpold_dir

# generate ftp commands to delete all files on current ftp svr
while read filename; do
    if [ ! -z "$filename" ]; then
        echo "delete $filename" >>tftpcore.sh
    fi
done <$ftplist

# generate ftp commands to delete all directories on current ftp svr
while read dir_name; do
    if [ ! -z "$dir_name" ]; then
        echo "rmdir $dir_name" >>tftpcore.sh
    fi
done <$ftpold_dir

echo "" >>tftpcore.sh

# generate ftp commands to create directories to current ftp svr from current update filenames
while read dir_name; do
    indir=$dir_name
    # create subdirectory by recursion
    while true; do
        iroot=$(echo "$indir" | sed -e 's/^\([a-z0-9]*\)\/\(.*\)/\1/')
        mroot=$(echo "$dir_name" | sed -e 's/^\([a-z0-9]*\)\/\(.*\)/\1/')
        if [ "$iroot" = "$mroot" ]; then
            mdir=$iroot
        else
            sedpatt="s/\(.*\)\/${iroot}\(.*\)/\1/"
            mdir=$(echo $dir_name | sed -e $sedpatt)/$iroot
        fi
        iztest=$(grep "mkdir $mdir" tftpcore.sh)
        if [ -z "$iztest" ]; then
            echo "mkdir $mdir" >>tftpcore.sh
        fi
        isubdir=$(echo "$indir" | sed -e 's/^\([a-z0-9]*\)\/\(.*\)/\2/')
        itest=$(echo "$isubdir" | grep "/")
        if [ -z "$itest" ]; then
            iztest=$(grep "mkdir $mdir" tftpcore.sh)
            if [ -z "$iztest" ]; then
                echo "mkdir $dir_name" >>tftpcore.sh
            fi
            break
        fi
        indir=$isubdir
    done
done <$ftpnew_dir

# upload needlist files
cat $needlist | awk -F"," '{printf("put ParaEngineSDK/%s %s\n",$1,$2)}' >>tftpcore.sh

echo "bye" >>tftpcore.sh
echo "!" >>tftpcore.sh
echo "echo update core files successed!" >>tftpcore.sh

# fix Assets_manifest0.txt and version.txt paths
sed -e 's/put ParaEngineSDK\/installer\/Aries\/Assets_manifest0.txt/put Assets_manifest0.txt/g' -e 's/put ParaEngineSDK\/version.txt/put version.txt/g' tftpcore.sh >tftpcore0.sh

# clean things
rm -f $ftpnew_dir
rm -f $ftplist
rm -f $ftpold_dir

rm -f tftpcore.sh
mv tftpcore0.sh tftpcore.sh
