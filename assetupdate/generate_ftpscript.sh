#!/bin/bash


# get directory names from current assets update files
sed -e 's/\(.*\)\/\(.*\)/\1/' need_upload.txt |grep -v ".svn"|sort|uniq > ftpnew_dir.txt

wget "http://192.168.0.228/assetdownload/list/ftpsvrlist.txt" -O ./ftpsvrlist.txt
wget "http://192.168.0.228/assetdownload/list/ftpsvrlist0.txt" -O ./ftpsvrlist0.txt






# generate FTP scripts to tftpasset.sh

echo "#!/bin/bash" > tftpasset.sh
echo "ftp -n << !" >> tftpasset.sh
echo "open 192.168.0.228" >> tftpasset.sh
echo "user ftpasset ftpparaengine" >> tftpasset.sh
echo "case"  >> tftpasset.sh

# delete all files & dir on asset ftp server
while read filename
do
  if [ ! -z "$filename" ];then
    echo "delete $filename" >> tftpasset.sh
  fi
done < ftpsvrlist.txt

# generate ftp commands to create new directories to current ftp svr from current update filenames
while read dir_name
do
  indir=$dir_name
  # create subdirectory by recursion
  while true
  do
    iroot=`echo "$indir" | sed -e 's/^\([a-z_0-9]*\)\/\(.*\)/\1/'`
    mroot=`echo "$dir_name" | sed -e 's/^\([a-z_0-9]*\)\/\(.*\)/\1/'`
    if [ "$iroot" = "$mroot" ];then
      mdir=$iroot"/"
    else
      bslash='\/'
      b2slash='\\\/'
      iroot0=`echo ${iroot} | sed s/$bslash/$b2slash/g`
      mdir=`echo $dir_name |awk -F"\/${iroot0}" '{print $1}'`"/"$iroot"/"
    fi

    # echo $mdir
    iztest=`grep "$mdir"  ftpsvrlist0.txt`
    izztest=`grep "$mdir" tftpasset.sh`
    if [[ -z "$iztest" && -z "$izztest" ]];then
      echo "mkdir $mdir" >> tftpasset.sh
      #   echo "mkdir $mdir"
    fi
    isubdir=`echo "$indir" | sed -e 's/^\([a-z_0-9]*\)\/\(.*\)/\2/'`
    itest=`echo "$isubdir"| grep "/"`
    # echo "===",$isubdir, $itest
    # echo $isubdir
    if [ -z "$itest" ];then
      iztest=`grep "$dir_name/"  ftpsvrlist0.txt`
      izztest=`grep "$dir_name/" tftpasset.sh`
      if [[ -z "$iztest" &&  -z "$izztest" ]];then
        echo "mkdir $dir_name" >> tftpasset.sh
        #     echo "mkdir $dir_name"
      fi
      break
    fi
    #       echo $iroot, $isubdir
    indir=$isubdir
  done

done < ftpnew_dir.txt

# generate ftp commands to put files to ftp svr
# FIXME why? dat20
cat need_upload.txt | awk -F"._dat20" '{printf("put ParaEngineSDK/%s %s\n",$1,$0)}' >> tftpasset.sh

echo "bye" >> tftpasset.sh
echo "!">> tftpasset.sh
echo "echo update asset files successed!" >> tftpasset.sh

#rm ftpnew_dir.txt -f
rm ftpsvrlist.txt -f

