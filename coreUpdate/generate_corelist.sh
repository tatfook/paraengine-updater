#!/usr/bin/env bash


teentag=""
if [ $# -eq 1 ] ; then
  teentag=$1
fi

if [ "$teentag" == "teen" ];then
  listfile="Aries_installer_teen.txt"
  updatelist="coreupdate_teen.list"
  needlist="core_need_teen.list"
else
  listfile="Aries_installer_v1.txt"
  updatelist="coreupdate.list"
  needlist="core_need.list"
fi

rm -f $needlist

# get scope of the lines from Aries_installer_v1.txt for analysing, exclude remark lines, space lines.
sed -n '/# Aries Client Core File List/,/# Post setup/p'  ParaEngineSDK/$listfile  | \
  sed -e 's/^[\t ]*//g' -e '/^[#;]/d' -e '/^[[:space:]]*$/d'  -e 's/\\/\\\\/g' -e 's/\$/\\$/g'  > $updatelist

remotePath=""
while read line
do
  testPath=`echo $line |grep -E "^SetOutPath"`

  # from line including SetOutPath to get directory of files, use var remotePath to keep current path of this SetOutPath
  if [ ! -z "$testPath" ];then
    remotePath=""
    remotePath0=`echo $line | sed -e 's/SetOutPath \\$INSTDIR//g' -e '/^[[:space:]]*$/d'`
    if [ ! -z "$remotePath0" ];then
      temp_path=`echo $remotePath0|sed -e 's/\\///g' -e 's/[ \t]*//g'`
      len_0=${#temp_path}
      (( len_0-- ))
      remotePath=`echo $temp_path | cut -c 2-$len_0 | tr A-Z a-z`
    fi
  else
    testFoname=`echo $line|grep -E "^File /oname"`
    if [ ! -z "$testFoname" ];then
      remotefile=`echo $line|awk -F" " '{print $2}'|cut -d= -f2 | sed -e 's/\\\\/\//g' | tr A-Z a-z`
      localfile=`echo $line|awk -F" " '{print $3}'|cut -d'"' -f2 | sed -e 's/\\\\/\//g'`
      filetype=`echo $line|awk -F" " '{print $4}'|awk -F"=" '{printf("%d",$2)}'`
      if [ -z "$remotePath" ];then
        echo "$localfile,${remotefile}._P_E_$filetype" >> $needlist
      else
        echo "$localfile,$remotePath/${remotefile}._P_E_$filetype" >> $needlist
      fi
    else
      # check "/r" to search files in recursion subdirectories
      testFr=`echo $line|grep -E "^File /r "`
      if [ ! -z "$testFr" ];then
        localfiles=`echo $line|awk -F" " '{print $3}'| sed -e 's/\\\\/\//g' `
        filetype=`echo $line|awk -F" " '{print $4}'|awk -F"=" '{printf("%d",$2)}'`
        remotefiles=(`find ParaEngineSDK/$localfiles`)
        for tfile in  ${remotefiles[@]};do
          localfile=`echo $tfile|sed -e 's/ParaEngineSDK\///'`
          remotefile=`echo $localfile| tr A-Z a-z`
          echo "$localfile,${remotefile}._P_E_$filetype" >> $needlist
        done
      fi

      # processing normal lines
      testFile=`echo $line|grep -E "^File" | grep -v "File /oname"`
      if [ ! -z "$testFile" ];then
        remotefile=`echo $line|awk -F" " '{print $2}'| sed -e 's/\\\\/\//g'| tr A-Z a-z`
        localfile=$remotefile
        filetype=`echo $line|awk -F" " '{print $3}'|awk -F"=" '{printf("%d",$2)}'`
        echo "$localfile,${remotefile}._P_E_$filetype" >> $needlist
      fi
    fi
  fi
done < $updatelist

rm -f $updatelist
