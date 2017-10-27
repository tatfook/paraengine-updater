#!/usr/bin/env bash

# 处理新旧版本文件夹的文件对比，及逐个压缩、MD5、文件长度，
# 生成版本比较清单、当前版本列表
generate_version_patch() {
  current_version_dir=$1
  old_version_dir=$2
  rev_number=$3

  if [ ! -e "/var/www/coredownload/list/temp012.txt" ];then
    echo "error! function generate_new_version_files doesn't produce a record file"
    exit 1;
  fi

  update_download_dir="/var/www/coredownload/update"
  while read line
  do
    current_version_file_path=`echo $line|cut -d"," -f1`
    file_md5=`echo $line|cut -d"," -f2`
    file_type=`echo $line|cut -d"," -f4`

    update_download_file_path=$update_download_dir${current_version_file_path/$current_version_dir/""}
    update_download_file_dir=`dirname $update_download_file_path`
    if [ "$update_download_file_dir" != "$update_download_dir" ];then
      mkdir -p $update_download_file_dir
    fi

    old_version_file_path=${current_version_file_path/$current_version_dir/$old_version_dir}
    update_download_zip_file_path=${update_download_file_path}.p
    zip_file_name=${current_version_file_path/$current_version_dir/""}.p

    ftp_file_name=${current_version_file_path/"${current_version_dir}/"/""}._P_E_${file_type}

    case "$file_type" in
      0)
        # 如果是x.x.0 版本，则按大版本升级处理
        if [ $rev_number -eq 0 ]; then
          gzip -n -c -q  "$current_version_file_path" > "$update_download_zip_file_path"
          md5_digest=$(md5sum "$update_download_zip_file_path"|awk '{print $1}')
          file_size=$(ls -l "$update_download_zip_file_path"|awk '{print $5}')
          echo "$zip_file_name","$md5_digest","$file_size","$file_type","$file_md5", >> /var/www/coredownload/list/full.txt
          echo "$ftp_file_name" >> /var/www/coredownload/list/ftpcorelist.txt
        else

          # FIXME ?? what's the point of -f?  难道不是每个old_version_file_path都是文件吗？
          if [ -f "$old_version_file_path" ]; then
            diff -q "$current_version_file_path" "$old_version_file_path" > /dev/null
            # $? -eq 0 means files are same
            diff_result=$?

            gzip -n -c -q  "$current_version_file_path" > "$update_download_zip_file_path"
            md5_digest=$(md5sum "$update_download_zip_file_path"|awk '{print $1}')
            file_size=$(ls -l "$update_download_zip_file_path"|awk '{print $5}')

            if [ $diff_result -ne 0 ]; then
              echo "$zip_file_name","$md5_digest","$file_size","$file_type","$file_md5", >> /var/www/coredownload/list/tdiff.txt
            fi

          else
            gzip -c -q -n  "$current_version_file_path" > "$update_download_zip_file_path"
            md5_digest=$(md5sum "$update_download_zip_file_path"|awk '{print $1}')
            file_size=$(ls -l "$update_download_zip_file_path"|awk '{print $5}')
            echo "$zip_file_name","$md5_digest","$file_size","$file_type","$file_md5", >> /var/www/coredownload/list/tdiff.txt
          fi

          # FIXME why rev_number -eq 1 is special?
          if [ $rev_number -eq 1 ]; then
            echo "$zip_file_name","$md5_digest","$file_size","$file_type","$file_md5", >> /var/www/coredownload/list/full.txt
            echo "$ftp_file_name" >> /var/www/coredownload/list/ftpcorelist.txt
          fi

        fi
        ;;
      [1,3])
        gzip -n -c -q  "$current_version_file_path" > "$update_download_zip_file_path"
        md5_digest=$(md5sum "$update_download_zip_file_path"|awk '{print $1}')
        file_size=$(ls -l "$update_download_zip_file_path"|awk '{print $5}')
        if [ $rev_number -eq 0 ]; then
          echo "$zip_file_name","$md5_digest","$file_size","$file_type","$file_md5", >> /var/www/coredownload/list/full.txt
          echo "$ftp_file_name" >> /var/www/coredownload/list/ftpcorelist.txt
        else
          echo "$zip_file_name","$md5_digest","$file_size","$file_type","$file_md5", >> /var/www/coredownload/list/tdiff.txt
          if [ $rev_number -eq 1 ]; then
            echo "$zip_file_name","$md5_digest","$file_size","$file_type","$file_md5", >> /var/www/coredownload/list/full.txt
            echo "$ftp_file_name" >> /var/www/coredownload/list/ftpcorelist.txt
          fi
        fi
        ;;

      *)
        echo "Wrong filetype!"
        echo $current_version_file_path, $file_type
        exit 1;
        ;;
    esac
  done < /var/www/coredownload/list/temp012.txt
}


generate_new_version_files() {
  # $1  root directory of source
  # $2  same as $1 only for recursion
  # $3  root directory of dest

  src_dir=$1
  first_called_src_dir=$2
  dest_dir=$3
  for src_dir_element in $src_dir/*
  do
    if [ -d "$src_dir_element" ]; then
      dest_element=$dest_dir${src_dir_element/$first_called_src_dir/""}  # dst directory
      if [ ! -d $dest_element ]; then
        mkdir -p $dest_element
      fi
      generate_new_version_files $src_dir_element "$first_called_src_dir" "$dest_dir"
    else
      if [ -f "$src_dir_element" ]; then
        pos=$(expr "$src_dir_element" : '.*\._P_E_')  # recover filename from filename of ftp files (filename._P_E_n)
        if [ $pos -gt 6 ]; then
          src_filename=${src_dir_element:0:pos-6}
          src_filetype=${src_dir_element:pos:1}
        else
          src_filename=$src_dir_element
          src_filetype=""
        fi
        dest_file=${src_filename/$first_called_src_dir/$dest_dir}           # dst ver's file
        src_file=$src_dir_element
        test_deletefile=`basename "$dest_file"`
        if [ "$test_deletefile" == "deletefile.list" ];then
          cat "$src_file" |sed -e 's/[ \t]//g' | tr -s '\r\n' '\n' | sed -e '/^$/d' | awk '{line[NR]=$0} END{ for (;++i < NR;){ print line[i]} printf line[NR]}'  >  "$dest_file"
        else
          cp "$src_file" "$dest_file"
        fi
        md5_digest=$(md5sum "$dest_file"|awk '{print $1}')
        dest_filesize=$(ls -l "$dest_file"|awk '{print $5}')
        if [ ! -z "$src_filetype" ];then
          echo "$dest_file","$md5_digest","$dest_filesize","$src_filetype" >> /var/www/coredownload/list/temp012.txt  # generate current ver file list
        fi
      fi
    fi
  done
}

rm -rf /var/www/coredownload/update/
mkdir -p /var/www/coredownload/update

# 取version.txt 配置信息，自动去除前后空格、TAB空格
while read xx
do
  aa=$(echo $xx |awk -F"=" '/ver/{print $2}')
  if [ -n "$aa" ]; then
    version_number=$(echo $aa|sed 's/^[ \t]*//g; s/[ \t]*$//g; s/[\n\r]//g')
  fi
done < /home/ftpuser1/version.txt._P_E_0

if [ -z "$version_number" ]; then
  echo "ver item doesnot find in version.txt!"
  exit 1
fi

# version desc: major.minor.revision
minor_revison_dot_pos=$(expr "$version_number" : '[0-9]*\.[0-9]*\.')
revision_number=${version_number:minor_revison_dot_pos}
# extract "major.minor."
major_minor_dot=${version_number:0:minor_revison_dot_pos}

if [ $revision_number -eq 0 ]; then
  rm -rf /var/www/prog/*
  rm -rf /var/www/coredownload/*
  mkdir -p /var/www/coredownload/list/
  mkdir -p /var/www/coredownload/update/
fi

rm -f /var/www/coredownload/list/full.txt
echo "" > /var/www/coredownload/list/ftpcorelist.txt

if [ -d "/var/www/prog/$version_number" ]; then
  cd "/var/www/prog/$version_number"
else
  mkdir /var/www/prog/$version_number
fi

httpdr="/var/www/coredownload/update"   # http download directory
# copy 当前版本到相应版本备份目录

rm /var/www/coredownload/list/temp012.txt -f

generate_new_version_files /home/ftpuser1 /home/ftpuser1 /var/www/prog/$version_number


# delete old version update directories
udir=(`ls /var/www/coredownload -F |grep '/'|sed -e 's/list\///g; s/update\///g'|sed -e '/^$/d'`)
for d in  ${udir[@]};do
  rm /var/www/coredownload/$d -rf
done

rm -f /var/www/coredownload/update/main*.pkg.p

current_version_dir=/var/www/prog/$version_number
# ver x.x.0 donot need to make patch files, directly calc their MD5, size into */full.txt
if [ $((revision_number-=1)) -lt 0 ]; then
  generate_version_patch $current_version_dir "" 0
else
  # diff latest version with 20 older version, make patch file list
  version_patch_limit=20
  # 小版本循环次数标志
  count=1
  while [ $revision_number -ge 0 ]
  do
    if [[ $count -le $version_patch_limit ]];then
      old_version_download_dir="/var/www/coredownload/$major_minor_dot$revision_number"   # ver update directory
      if [ -d "$old_version_download_dir" ]; then
        rm -rf $old_version_download_dir   # delete old version update dir
      fi

      tdiff_file=/var/www/coredownload/list/tdiff.txt
      echo "" > $tdiff_file
      old_version_dir="/var/www/prog/$major_minor_dot$revision_number"
      if [ ! -d "$old_version_dir" ]; then
        echo "error! no $old_version_dir"
        exit 1
      fi

      generate_version_patch $current_version_dir $old_version_dir $count
      if [ $? -ne 0 ]; then
        echo 'function generate_version_patch failure!'
        exit 1
      fi

      tmp_patch_list_file=/var/www/coredownload/list/patch0_$major_minor_dot$revision_number.txt
      patch_list_file_txt=/var/www/coredownload/list/patch_$major_minor_dot$revision_number.txt
      patch_list_file_p=/var/www/coredownload/list/patch_$major_minor_dot$revision_number.p

      # sort manifest file on filesize & replace the root directory with path item in verion.txt
      grep -e ",0," $tdiff_file | sort -n -t, -r -k 3,3 > $tmp_patch_list_file
      grep -e ",[1-3]," $tdiff_file | sort -n -t, -r -k 3,3 >> $tmp_patch_list_file

      # 去掉manifest file 的各行开始字符
      cut -c 2-200 $tmp_patch_list_file > $patch_list_file_txt
      rm -f $tmp_patch_list_file
      cp $patch_list_file_txt $patch_list_file_p
    else
      cut -c 2-200 /var/www/coredownload/list/full.txt > $patch_list_file_txt
      cp $patch_list_file_txt $patch_list_file_p
      # delete older version before 20 verisons
      rm -rf /var/www/prog/$major_minor_dot$revision_number/
    fi
    ((revision_number-=1))
    ((count+=1))
  done
fi

cp -a /var/www/coredownload/list/ftpcorelist.txt ftpcorelist.txt

# sort 当前版本 on filesize & replace the root directory with path item in verion.txt
# 去掉manifest file 的各行开始字符
grep -e ",0,"  /var/www/coredownload/list/full.txt |sort -n -t, -r -k 3,3 > /var/www/coredownload/list/full1.txt
grep -e ",[1-3]," /var/www/coredownload/list/full.txt | sort -n -t, -r -k 3,3 >> /var/www/coredownload/list/full1.txt

cut -c 2-200 /var/www/coredownload/list/full1.txt > /var/www/coredownload/list/full.txt
rm -f /var/www/coredownload/list/full1.txt
cp /var/www/coredownload/list/full.txt /var/www/coredownload/list/full.p

testfull=`cut -d, -f2 /var/www/coredownload/list/full.txt |sort|uniq -c|sort -k1 -r|head -n1`
lineno=`echo $testfull|awk -F" " '{print $1}'`
md5=`echo $testfull|awk -F" " '{print $2}'`
errfile=`grep $md5 /var/www/coredownload/list/full.txt`

if [ "$lineno" -gt 1 ];then
  echo "Theres is $lineno files with same md5 in full.txt."
  echo "--------------------------------------------------"
  echo "$errfile"
  exit 1
fi


# generate current ver update dir
mkdir -p /var/www/coredownload/$version_number
cp -r  /var/www/coredownload/list/  /var/www/coredownload/$version_number/list/
cp -r  /var/www/coredownload/update/  /var/www/coredownload/$version_number/update/

echo "<UpdateVersion>" > /var/www/coredownload/version.txt
echo $version_number >> /var/www/coredownload/version.txt
echo "</UpdateVersion>" >> /var/www/coredownload/version.txt
echo "<FullUpdatePackUrl>" >> /var/www/coredownload/version.txt
echo http://update.61.com/haqi/coreupdate/coredownload/list/full.txt >> /var/www/coredownload/version.txt
echo "</FullUpdatePackUrl>" >> /var/www/coredownload/version.txt

cp /var/www/coredownload/version.txt /var/www/refresh_time/version.txt

rm -rf /var/www/coredownload/update/
mkdir -p /var/www/coredownload/update


fpath="/var/www/coredownload/"$version_number"/update"
dpath="/var/www/coredownload/update"
while read  xx
do
  orgfile=`echo $xx |cut -d, -f1`
  filenm=`echo $xx |cut -d, -f1,2,3`".p"
  echo $orgfile"|"$filenm
  testdir=`echo $orgfile|grep "/"`
  if [ ! -z "$testdir" ];then
    ddir=`echo $orgfile|cut -d"/" -f1`
    mkdir -p $dpath/$ddir
  fi
  cp $fpath/$orgfile $dpath/$filenm
done < /var/www/coredownload/list/full.txt

rm -f /var/www/coredownload/list/patch*.*
exit 0
