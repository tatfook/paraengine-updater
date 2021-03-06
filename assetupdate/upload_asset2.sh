#!/bin/bash
#

# usage:
#   fullver /home/ftpasset /home/ftpasset $xdir ""
#
fullver(){
  # $1  root directory of new version
  # $2  same as $1 only for recursion
  # $3  root directory of old version

  httpdir="/var/www/assetdownload/update"  # http download root directory

  for vfile in $1/*
  do
    if [[ -d "$vfile" ]]; then
      httpd0=$httpdir${vfile/$2/""}  # relative path
      httpd0=$(echo "$httpd0"|tr A-Z a-z)   # change chars to lower char
      dir0=${vfile/$2/$3}
      dir0=$(echo "$dir0"|tr A-Z a-z)
      if [ -d $dir0 ]; then
        :
      else
        mkdir $dir0
      fi
      if [ -d $httpd0 ]; then
        :
      else
        mkdir $httpd0
      fi
      echo '====================================='
      echo Processing $vfile '... '
      echo '====================================='
      fullver $vfile "$2" "$3"
    else
      if [ -f "$vfile" ]; then
        # skip file /home/ftpasset/ftpsvrlist.txt
        if [ "$vfile" != "/home/ftpasset/ftpsvrlist.txt" ]; then
          # recover filename from filename of ftp files (filename._datYYYYMMDD_lnnnn)
          pos=$(expr "$vfile" : '.*\._dat')
          if [ $pos -gt 5 ]; then
            vfn=${vfile:0:pos-5}
          else
            vfn=$vfile
          fi

          httpf=$httpdir${vfn/$2/""}.z    # new patch file name(*.z)
          httpf=$(echo "$httpf"|tr A-Z a-z) # change  chars to lower char
          httpfl=${vfn/$2/""}.z       # write in tdiff.txt patch file name
          httpfl=$(echo "$httpfl"|tr A-Z a-z)   # change  chars to lower char
          oldfile=${vfn/$2/$3}                # old ver's file
          fs_old=${vfn/$2/""}

          dp=$2"/"
          ftpfile=${vfile/$dp/""}
          echo "$ftpfile" >> /var/www/assetdownload/list/ftpsvrlist.txt

          f_old=${vfn/$dp/""}
          echo $f_old

          f_old=$(echo $f_old | sed 's/\//\\\//g')
          f_new=$(echo $ftpfile | sed 's/\//\\\//g')

          if [ -f "/var/www/assetdownload/list/ftpsvrlist0.txt" ]; then
            echo "$2",,,"$f_old" >> "/var/www/assetdownload/list/ftp_log0.txt"
            t0=$(cat "/var/www/assetdownload/list/ftpsvrlist0.txt" | grep "$f_old")
            if [ "$t0" != "" ]; then
              p="s/$f_old\._dat[0-9]*\-[0-9]*\-[0-9]*\-[0-9]*\-[0-9]*_l[0-9]*//g"
              cat "/var/www/assetdownload/list/ftpsvrlist0.txt" | sed -e $p > "/var/www/assetdownload/list/ftpsvrlist00.txt"
              echo "$ftpfile" >> "/var/www/assetdownload/list/ftpsvrlist00.txt"
              sed '/^$/d' "/var/www/assetdownload/list/ftpsvrlist00.txt" > "/var/www/assetdownload/list/ftpsvrlist0.txt"
            else
              echo "$ftpfile" >> "/var/www/assetdownload/list/ftpsvrlist0.txt"
            fi
          else
            echo "$ftpfile" >> "/var/www/assetdownload/list/ftpsvrlist0.txt"
          fi

          rm -f "/var/www/assetdownload/list/ftpsvrlist00.txt"

          oldfile=$(echo "$oldfile"|tr A-Z a-z) # change  chars to lower char

          if [ -f "$oldfile" ]; then
            diff -q "$vfile" "$oldfile" > /dev/null
            if [ $? -ne 0 ]; then
              cp "$vfile" "$oldfile"
              zip -j "$httpf" "$oldfile"  > /dev/null
              o_size=`ls "$oldfile" -l |cut -d" " -f5 ` # original file length
              c_size=`ls "$httpf" -l |cut -d" " -f5 `   # compressed file length
              diff_size=`expr $o_size - $c_size`
              suffix=${filenm##*\.}
              if [[ "$o_size" -gt "4096" && "$diff_size" -gt "4096" ]];then
                c_rate=`echo "scale=0;$c_size*100/$o_size"|bc`
                if [[ "$c_rate" -le "75" && "suffix" != "jpg" && "suffix" != "png" && "suffix" != "swf" ]];then
                  crc32v=$(md5sum "$httpf"|awk '{print $1}')
                  sizev=$c_size
                  echo "$httpfl","$crc32v","$sizev" >> /var/www/assetdownload/list/tdiff.txt
                else
                  rm -f "$httpf"  # delete compressed file
                  crc32v=$(md5sum "$oldfile"|awk '{print $1}')
                  httpfl=$(echo $httpfl|sed -e 's/\.z/\.p/')
                  httpf=$(echo $httpf|sed -e 's/\.z/\.p/')
                  sizev=$o_size
                  cp "$oldfile" "$httpf" # use original file
                  echo "$httpfl","$crc32v","$sizev" >> /var/www/assetdownload/list/tdiff.txt
                fi
              else
                rm -f "$httpf"  # delete compressed file
                crc32v=$(md5sum "$oldfile"|awk '{print $1}')
                httpfl=$(echo $httpfl|sed -e 's/\.z/\.p/')
                httpf=$(echo $httpf|sed -e 's/\.z/\.p/')
                sizev=$o_size
                cp "$oldfile" "$httpf" # use original file
                echo "$httpfl","$crc32v","$sizev" >> /var/www/assetdownload/list/tdiff.txt
              fi
              fs_old1=$(echo "$httpfl" | sed -e's/\//\\\//g' -e's/\./\\\./g')
              pattern="/$fs_old1,/d"
              cat /var/www/assetdownload/list/full0.txt | sed $pattern > /var/www/assetdownload/list/full00.txt
              echo "$httpfl","$crc32v","$sizev" >> /var/www/assetdownload/list/full00.txt
              sed '/^$/d' /var/www/assetdownload/list/full00.txt >  /var/www/assetdownload/list/full0.txt

              verfnm="$httpf","$crc32v","$sizev"
              cp "$httpf" "$verfnm"
            fi
          else
            cp "$vfile" "$oldfile"
            zip -j "$httpf" "$oldfile"  > /dev/null
            o_size=`ls "$oldfile" -l |cut -d" " -f5 ` # original file length
            c_size=`ls "$httpf" -l |cut -d" " -f5 `   # compressed file length
            diff_size=`expr $o_size - $c_size`
            suffix=${filenm##*\.}
            cat /var/www/assetdownload/list/full0.txt > /var/www/assetdownload/list/full00.txt
            if [[ "$o_size" -gt "4096" && "$diff_size" -gt "4096" ]];then
              c_rate=`echo "scale=0;$c_size*100/$o_size"|bc`
              if [[ "$c_rate" -le "75" && "suffix" != "jpg" && "suffix" != "png" && "suffix" != "swf" ]];then
                crc32v=$(md5sum "$httpf"|awk '{print $1}')
                sizev=$c_size
                echo "$httpfl","$crc32v","$sizev" >> /var/www/assetdownload/list/tdiff.txt
                echo "$httpfl","$crc32v","$sizev" >> /var/www/assetdownload/list/full00.txt
                sed '/^$/d' /var/www/assetdownload/list/full00.txt >  /var/www/assetdownload/list/full0.txt

              else
                rm -f "$httpf"  # delete compressed file
                crc32v=$(md5sum "$oldfile"|awk '{print $1}')
                httpfl=$(echo $httpfl|sed -e 's/\.z/\.p/')
                httpf=$(echo $httpf|sed -e 's/\.z/\.p/')
                sizev=$o_size
                cp "$oldfile" "$httpf" # use original file
                echo "$httpfl","$crc32v","$sizev" >> /var/www/assetdownload/list/tdiff.txt
                echo "$httpfl","$crc32v","$sizev" >> /var/www/assetdownload/list/full00.txt
                sed '/^$/d' /var/www/assetdownload/list/full00.txt >  /var/www/assetdownload/list/full0.txt
              fi
            else
              rm -f "$httpf"  # delete compressed file
              crc32v=$(md5sum "$oldfile"|awk '{print $1}')
              httpfl=$(echo $httpfl|sed -e 's/\.z/\.p/')
              httpf=$(echo $httpf|sed -e 's/\.z/\.p/')
              sizev=$o_size
              cp "$oldfile" "$httpf" # use original file
              echo "$httpfl","$crc32v","$sizev" >> /var/www/assetdownload/list/tdiff.txt
              echo "$httpfl","$crc32v","$sizev" >> /var/www/assetdownload/list/full00.txt
              sed '/^$/d' /var/www/assetdownload/list/full00.txt >  /var/www/assetdownload/list/full0.txt
            fi
            verfnm="$httpf","$crc32v","$sizev"
            cp "$httpf" "$verfnm"
          fi
        fi
      fi
    fi
  done
}

xdir="/var/www/asset"   # ver copy directory

echo "" > /var/www/assetdownload/list/tdiff.txt
echo "" > /var/www/assetdownload/list/ftpsvrlist.txt
echo "" > /var/www/assetdownload/list/ftp_log0.txt

if [ ! -d "$xdir" ]; then
  echo error! no $xdir
  exit 1
fi

sudo chmod -R o+r /home/ftpasset
sudo chmod -R o+w /home/ftpasset
sudo chmod -R o+r /var/www/assetdownload
sudo chmod -R o+w /var/www/assetdownload
sudo chmod -R o+r /var/www/asset
sudo chmod -R o+w /var/www/asset

# call function fullver for recursion
# FIXME uncomment me
fullver /home/ftpasset /home/ftpasset $xdir

cp -f /var/www/assetdownload/list/ftpsvrlist.txt /home/ftpasset/ftpsvrlist.txt

# sort manifest file on filesize & replace the root directory with path item in verion.txt
sort -n -t, -r -k 3 /var/www/assetdownload/list/tdiff.txt -o /var/www/assetdownload/list/patch0.txt
cut -c 2-200 /var/www/assetdownload/list/patch0.txt > /var/www/assetdownload/list/patch.txt

sort -n -t, -r -k 3 /var/www/assetdownload/list/full0.txt -o /var/www/assetdownload/list/full1.txt
cut -c 2-200 /var/www/assetdownload/list/full1.txt > /var/www/assetdownload/list/full.txt

exit 0
