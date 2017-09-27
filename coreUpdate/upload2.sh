#!/usr/bin/env bash

# every uploading must with version info file named /home/upload/version.txt.
# version.txt's standard content like this:
# ver = x.x.x
#
# 递归处理新旧版本文件夹的文件对比，及逐个压缩、MD5、文件长度，
# 生成版本比较清单、当前版本列表

fullver(){
  # $1  root directory of new version
  # $2  same as $1 only for recursion
  # $3  root directory of old version
  #
  # $4  path item in version.txt, relative root directory to ParaEngineSDK & webdownload (default download url: http://x.x.x/update/, default value is "/"  )
  # $5  label for indicate if the version is x.x.0 or not

  httpdir="/var/www/coredownload/update"  # http download root directory
  if [ ! -e "/var/www/coredownload/list/temp012.txt" ];then
    echo "temp012.txt doesnot exist!"
    exit 1;
  else
    while read vfile
    do
      srcfile=`echo $vfile|cut -d"," -f1`
      md5src=`echo $vfile|cut -d"," -f2`
      file_type=`echo $vfile|cut -d"," -f4`

      httpd0=$httpdir${srcfile/$2/""}  # http download directory
      dir0=`dirname $httpd0`
      if [ "$dir0" != "$httpdir" ];then
        mkdir -p $dir0
      fi

      oldfile=${srcfile/$2/$3}           # old ver's file
      httpf=$httpdir${srcfile/$2/""}.p   # new patch file name(*.p)
      httpfl="$4"${srcfile/$2/""}.p      # write in tdiff.txt patch file name
      dp=$2"/"
      ftpfile=${srcfile/$dp/""}._P_E_${file_type}

      case "$file_type" in
        0)
          if [ $5 -eq 0 ]; then         # 如果是x.x.0 版本，则按大版本升级处理
            gzip -n -c -q  "$srcfile" > "$httpf"
            crc32v=$(md5sum "$httpf"|awk '{print $1}')
            sizev=$(ls -l "$httpf"|awk '{print $5}')
            echo "$httpfl","$crc32v","$sizev","$file_type","$md5src", >> /var/www/coredownload/list/full.txt
            echo "$ftpfile" >> /var/www/coredownload/list/ftpcorelist.txt  # generate current ftp file list
          else
            if [ -f "$oldfile" ]; then
              diff -q "$srcfile" "$oldfile" > /dev/null
              if [ $? -ne 0 ]; then           # 如果与老版本不县
                gzip -n -c -q  "$srcfile" > "$httpf"
                crc32v=$(md5sum "$httpf"|awk '{print $1}')
                sizev=$(ls -l "$httpf"|awk '{print $5}')
                echo "$httpfl","$crc32v","$sizev","$file_type","$md5src", >> /var/www/coredownload/list/tdiff.txt
              else                      # 计算与老版本一致的压缩文件MD5,文件大小
                gzip -n -c -q  "$srcfile" > "$httpf"
                crc32v=$(md5sum "$httpf"|awk '{print $1}')
                sizev=$(ls -l "$httpf"|awk '{print $5}')
              fi
              if [ $5 -eq 1 ]; then
                echo "$httpfl","$crc32v","$sizev","$file_type","$md5src", >> /var/www/coredownload/list/full.txt
                echo "$ftpfile" >> /var/www/coredownload/list/ftpcorelist.txt  # generate current ftp file list
              fi
            else                         # 如果是新文件
              gzip -c -q -n  "$srcfile" > "$httpf"
              crc32v=$(md5sum "$httpf"|awk '{print $1}')
              sizev=$(ls -l "$httpf"|awk '{print $5}')
              echo "$httpfl","$crc32v","$sizev","$file_type","$md5src", >> /var/www/coredownload/list/tdiff.txt
              if [ $5 -eq 1 ]; then
                echo "$httpfl","$crc32v","$sizev","$file_type","$md5src", >> /var/www/coredownload/list/full.txt
                echo "$ftpfile" >> /var/www/coredownload/list/ftpcorelist.txt  # generate current ftp file list
              fi
            fi
          fi
          ;;

        [1,3])
          if [ $5 -eq 0 ]; then         # 如果是x.x.0 版本，则按大版本升级处理
            gzip -n -c -q  "$srcfile" > "$httpf"
            crc32v=$(md5sum "$httpf"|awk '{print $1}')
            sizev=$(ls -l "$httpf"|awk '{print $5}')
            echo "$httpfl","$crc32v","$sizev","$file_type","$md5src", >> /var/www/coredownload/list/full.txt
            echo "$ftpfile" >> /var/www/coredownload/list/ftpcorelist.txt  # generate current ftp file list
          else

            gzip -n -c -q  "$srcfile" > "$httpf"
            crc32v=$(md5sum "$httpf"|awk '{print $1}')
            sizev=$(ls -l "$httpf"|awk '{print $5}')
            echo "$httpfl","$crc32v","$sizev","$file_type","$md5src", >> /var/www/coredownload/list/tdiff.txt
            if [ $5 -eq 1 ]; then
              echo "$httpfl","$crc32v","$sizev","$file_type","$md5src", >> /var/www/coredownload/list/full.txt
              echo "$ftpfile" >> /var/www/coredownload/list/ftpcorelist.txt  # generate current ftp file list
            fi
          fi
          ;;

        *)
          echo "Wrong filetype!"
          echo $srcfile, $file_type
          exit 1;
          ;;

        esac

      done < /var/www/coredownload/list/temp012.txt
    fi
  }


  copyver(){
    # $1  root directory of source
    # $2  same as $1 only for recursion
    # $3  root directory of dest

    dstroot=$3
    for vfile in $1/*
    do
      if [ -d "$vfile" ]; then
        dstsub=$dstroot${vfile/$2/""}  # dst directory
        if [ -d $dstsub ]; then
          :
        else
          mkdir -p $dstsub
        fi
        copyver $vfile "$2" "$3"
      else
        if [ -f "$vfile" ]; then
          pos=$(expr "$vfile" : '.*\._P_E_')  # recover filename from filename of ftp files (filename._P_E_n)
          if [ $pos -gt 6 ]; then
            vfn=${vfile:0:pos-6}
            file_type=${vfile:pos:1}
          else
            vfn=$vfile
            file_type=""
          fi
          dstfile=${vfn/$2/$3}           # dst ver's file
          scrfile=$vfile
          testdellst=`basename "$dstfile"`
          if [ "$testdellst" == "deletefile.list" ];then
            cat "$scrfile" |sed -e 's/[ \t]//g' | tr -s '\r\n' '\n' | sed -e '/^$/d' | awk '{line[NR]=$0} END{ for (;++i < NR;){ print line[i]} printf line[NR]}'  >  "$dstfile"
          else
            cp "$scrfile" "$dstfile"
          fi
          crc32v=$(md5sum "$dstfile"|awk '{print $1}')
          sizev=$(ls -l "$dstfile"|awk '{print $5}')
          if [ ! -z "$file_type" ];then
            echo "$dstfile","$crc32v","$sizev","$file_type" >> /var/www/coredownload/list/temp012.txt  # generate current ver file list
          fi
        fi
      fi
    done
  }

  rm -rf /var/www/coredownload/update/
  mkdir -p /var/www/coredownload/update

  # upload.sh 输出结果html 文件
  echo 'content-type: text/html'
  echo
  echo
  echo '<html><body>'
  #  取version.txt 配置信息，自动去除前后空格、TAB空格
  while read  xx
  do
    aa=$(echo $xx |awk -F"=" '/ver/{print $2}')
    if [ -n "$aa" ]; then
      x0=$(echo $aa|sed 's/^[ \t]*//g; s/[ \t]*$//g; s/[\n\r]//g')
    fi
  done < /home/ftpuser1/version.txt._P_E_0

  if [ -z "$x0" ]; then
    echo "ver item doesnot find in version.txt!"
    exit 1
  else
    verd=$x0
  fi

  # default path is root path /
  x2="/"

  # get revision number from x0(ver iterm in version.txt)
  xvn0=$(expr "$x0" : '[0-9]*\.[0-9]*\.')
  xvn=${x0:xvn0}
  # get "major.minor." from x0
  xvpr=${x0:0:xvn0}

  if [ $xvn -eq 0 ]; then
    # ver x.x.0 清除原版本备份文件、压缩文件及清单文件
    rm -rf /var/www/prog/*
    rm -rf /var/www/coredownload/*
    mkdir -p /var/www/coredownload/list/
    mkdir -p /var/www/coredownload/update/
  fi

  if [ -f /var/www/coredownload/list/full.txt ]; then
    rm -f /var/www/coredownload/list/full.txt
  fi

  echo "" > /var/www/coredownload/list/ftpcorelist.txt


  # 如果版本目录不存在，创建版本目录
  if [ -d "/var/www/prog/$verd" ]; then
    cd "/var/www/prog/$verd"
  else
    mkdir /var/www/prog/$verd
  fi

  echo '<hr> '
  httpdr="/var/www/coredownload/update"   # http download directory
  # copy 当前版本到相应版本备份目录

  rm /var/www/coredownload/list/temp012.txt -f
  copyver /home/ftpuser1 /home/ftpuser1 /var/www/prog/$verd

  # delete old version update directories
  udir=(`ls /var/www/coredownload -F |grep '/'|sed -e 's/list\///g; s/update\///g'|sed -e '/^$/d'`)
  for d in  ${udir[@]};do
    rm /var/www/coredownload/$d -rf
  done
  rm -f /var/www/coredownload/update/main*.pkg.p

  # ver x.x.0 donot need to make patch files, directly calc their MD5, size into */full.txt
  if [ $((xvn-=1)) -lt 0 ]; then
    if [ "$x2" = "/" ]; then
      fullver /var/www/prog/$verd /var/www/prog/$verd "" "" 0
    else
      fullver /var/www/prog/$verd /var/www/prog/$verd "" $x2 0
    fi
  else
    i=1  # 小版本循环次数标志
    while [ $xvn -ge 0 ]
    do
      if  [[ $i -le 20 ]];then
        xdir="/var/www/prog/$xvpr$xvn"   # ver copy directory
        echo "" > /var/www/coredownload/list/tdiff.txt

        xupdir="/var/www/coredownload/$xvpr$xvn"   # ver update directory
        if [ -d "$xupdir" ]; then
          rm -rf $xupdir   # delete old version update dir
        fi
        if [ -d "$xdir" ]; then
          if [ "$x2" = "/" ]; then
            fullver /var/www/prog/$verd /var/www/prog/$verd $xdir "" $i
          else
            fullver /var/www/prog/$verd /var/www/prog/$verd $xdir $x2 $i
          fi
          if [ $? -eq 0 ]; then
            # add updateversion.exe.p into patch list, to force update this file. 2010.4.16
            grep "updateversion.exe.p" /var/www/coredownload/list/full.txt >> /var/www/coredownload/list/patch0_$xvpr$xvn.txt

            # sort manifest file on filesize & replace the root directory with path item in verion.txt
            grep -e ",0," /var/www/coredownload/list/tdiff.txt | sort -n -t, -r -k 3,3 > /var/www/coredownload/list/patch0_$xvpr$xvn.txt
            grep -e ",[1-3]," /var/www/coredownload/list/tdiff.txt | sort -n -t, -r -k 3,3 >> /var/www/coredownload/list/patch0_$xvpr$xvn.txt

            # 去掉manifest file 的各行开始字符
            cut -c 2-200 /var/www/coredownload/list/patch0_$xvpr$xvn.txt > /var/www/coredownload/list/patch_$xvpr$xvn.txt
            rm -f /var/www/coredownload/list/patch0_$xvpr$xvn.txt
            cp /var/www/coredownload/list/patch_$xvpr$xvn.txt /var/www/coredownload/list/patch_$xvpr$xvn.p
            echo " <a href=\"/coredownload/list/patch_$xvpr$xvn.txt\">patch $xvpr$xvn list</a> <br>"
          else
            echo ' update failure!'
            exit 1
          fi
        else
          echo no $xdir
        fi

      else
        cut -c 2-200 /var/www/coredownload/list/full.txt > /var/www/coredownload/list/patch_$xvpr$xvn.txt
        cp /var/www/coredownload/list/patch_$xvpr$xvn.txt /var/www/coredownload/list/patch_$xvpr$xvn.p
        echo " <a href=\"/coredownload/list/patch_$xvpr$xvn.txt\">patch $xvpr$xvn list</a> <br>"
        # delete  older version before 20 verisons
        rm -rf /var/www/prog/$xvpr$xvn/
      fi
      ((xvn-=1))
      ((i+=1))
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
  mkdir -p /var/www/coredownload/$verd
  cp -r  /var/www/coredownload/list/  /var/www/coredownload/$verd/list/
  cp -r  /var/www/coredownload/update/  /var/www/coredownload/$verd/update/

  echo " <p><a href=\"/coredownload/list/full.txt\">The newest full version list</a>"
  echo "<UpdateVersion>" > /var/www/coredownload/version.txt
  echo $verd >> /var/www/coredownload/version.txt
  echo "</UpdateVersion>" >> /var/www/coredownload/version.txt
  echo "<FullUpdatePackUrl>" >> /var/www/coredownload/version.txt
  echo http://update.61.com/haqi/coreupdate/coredownload/list/full.txt >> /var/www/coredownload/version.txt
  echo "</FullUpdatePackUrl>" >> /var/www/coredownload/version.txt

  cp /var/www/coredownload/version.txt /var/www/refresh_time/version.txt

  echo '<hr><p> update to patch success! </p>'
  echo
  echo '</body></html>'

  rm -rf /var/www/coredownload/update/
  mkdir -p /var/www/coredownload/update

  fpath="/var/www/coredownload/"$verd"/update"
  dpath="/var/www/coredownload/update"
  while read  xx
  do
    orgfile=`echo $xx |cut -d, -f1`
    filenm=`echo $xx |cut -d, -f1,2,3`".p"
    echo $orgfile"|"$filenm
    testdir=`echo $orgfile|grep "/"`
    if [ -z "$testdir" ];then
      :
    else
      ddir=`echo $orgfile|cut -d"/" -f1`
      mkdir -p $dpath/$ddir
    fi
    cp $fpath/$orgfile $dpath/$filenm
  done < /var/www/coredownload/list/full.txt

  rm -f /var/www/coredownload/list/patch*.*
  exit 0
