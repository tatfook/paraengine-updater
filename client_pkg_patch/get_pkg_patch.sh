#!/usr/bin/env bash

# Usage: $0 basever|zipfile_patch.list
if [ $# -eq 0 ]; then
  basever=9857
else
  testp=`echo $1|grep -E "^[0-9]+$"`
  if [[ $# -eq 1 && ! -z "$testp" ]]; then
    basever=$1
  else
    if [ "$1" != "zipfile_patch.list" ];then
      echo "Wrong parameters! Usage: $(basename $0)  basever|zipfile_patch.list"
      exit 1
    else
      zippatch_list=$1
    fi
  fi
fi


# set timeout for npl shell compile lua script
# what does it do????
rm -rf bin log.txt
./ParaEngineServer 'bootstrapper="script/shell_compile.lua"'

sleep 1
i=1
grep "Compile END" log.txt
end_result=$?
echo "result is $end_result" >> log.txt
while [ $end_result -ne 0 ]
do
  sleep 1
  i=`expr $i + 1`
  grep "Compile END" log.txt > /dev/null
  end_result=$?
  echo "sleeping $i seconds"
  if [ $i -gt 50 ];then
    echo "sleeping too long" >> log.txt
    exit 1
  fi
done

echo "sleep $i seconds" >> log.txt



if [ -z "$zippatch_list" ];then
  # if param is basever
  conf_file="packages/redist/main_script-1.0.txt"

  rm -rf exclude_tmp0.txt exclude1_tmp0.txt exclude3_tmp0.txt

  grep "\[exclude\]" "$conf_file" | grep -v "^--" | sed -e 's/\[exclude\]//g'| sed -e 's/[\t ]*$//g' > exclude_tmp0.list
  grep "\[exclude1\]" "$conf_file" | grep -v "^--" | sed -e 's/\[exclude1\]//g'| sed -e 's/[\t ]*$//g' > exclude1_tmp0.list
  grep "\[exclude3\]" "$conf_file" | grep -v "^--" | sed -e 's/\[exclude3\]//g'| sed -e 's/[\t ]*$//g' > exclude3_tmp0.list


  rm -f exclude_tmp1.list

  while read xx
  do
    spath=`dirname $xx`/
    sname=`basename $xx| tr -s '\r\n' '\n'`
    find "$spath" -name "$sname"  >> exclude_tmp1.list
  done < exclude_tmp0.list

  while read xx
  do
    spath=`dirname $xx`/
    sname=`basename $xx| tr -s '\r\n' '\n'`
    find "$spath" -maxdepth 1 -iname "$sname"  >> exclude_tmp1.list
  done < exclude1_tmp0.list

  while read xx
  do
    spath=`dirname $xx`/
    sname=`basename $xx| tr -s '\r\n' '\n'`
    find "$spath" -maxdepth 3 -iname "$sname"  >> exclude_tmp1.list
  done < exclude3_tmp0.list

  grep -v ".svn" exclude_tmp1.list | sort | uniq > exclude_tmp0.list

  svn diff --summarize --username ci --password ci1234567 -r $basever svn://svn.paraengine.com/script/trunk/script | sed -rn 's/.*svn:.*script\/trunk\/(.*)/\1/p' > changelist.txt

  sed -n '/--------------------/,$p' "$conf_file" | grep -v "^--" | grep -v "\[exclude*" | sed -e 's/[\t ]*$//g' | grep -v "*" | tr -s '\r\n' '\n' > forceinclude.list

  sed -n '/--------------------/,$p' "$conf_file" | grep -v "^--" | grep -v "\[exclude*" | sed -e 's/[\t ]*$//g'|grep  "config/" > configtemp.txt

  rm -f configfiles.list
  while read xx0
  do
    path=`dirname $xx0`/
    name=`basename $xx0| tr -s '\r\n' '\n'`
    find "$path" -iname "$name"  >> configfiles.list
  done <  configtemp.txt

  basecfg_dir="./config"

  rm -f configpatch.list
  while read xx0
  do
    xx=`echo "$xx0"|sed -e 's/config\///'`
    if [ -f "$basecfg_dir/$xx" ];then
      line_ending=""
      if [ "${xx: -4}" == ".xml" ]; then
        line_ending="--strip-trailing-cr"
      fi
      diff -q "$basecfg_dir/$xx" "$xx0" $line_ending > /dev/null
      if [ $? -ne 0 ]; then
        echo $xx0 >> configpatch.list
      fi
    else
      echo $xx0 >> configpatch.list
    fi
  done < configfiles.list

  cat configpatch.list >> changelist.txt
  rm -f zipfile_patch.list
  rm -f patch_tmp1.list
  rm -f exclude_tmpx.list

  # add all changed files to patch_tmp1.list, Fixed force include *.lua
  # by LiXizhi 2015.7.19
  grep -v "^--" "$conf_file" | grep -v "\[exclude*" | sed -e 's/[\t ]*$//g' | grep "\*\.lua" | sed "s/\*\.lua//"| tr -s '\r\n' '\n' > forceincludelua.list

  function is_lua_file_forceinclude(){
    filename="$1"
    while read linetext
    do
      if [ "${filename#${linetext}}" != "$filename" ]; then
        return 0
      fi
    done <  forceincludelua.list
    return 1
  }

  while read linetext
  do
    script_regx="^script.*lua$"
    if [[ $linetext =~ $script_regx ]]; then
      if (is_lua_file_forceinclude "$linetext"); then
        echo $linetext >> patch_tmp1.list
      else
        echo "bin/${linetext%lua}o" >> patch_tmp1.list
      fi
    else
      echo $linetext >> patch_tmp1.list
    fi
  done <  changelist.txt

  # keep force include files
  sort exclude_tmp0.list|uniq > exclude_tmpx.list
  sort forceinclude.list exclude_tmpx.list | uniq -d > same_in.list
  sort exclude_tmpx.list same_in.list | uniq -u > exclude_tmp0.list

  # exclude files
  sort patch_tmp1.list | uniq > patch_tmp0.list
  sort patch_tmp0.list exclude_tmp0.list | uniq -d > same_tmp.list
  sort patch_tmp0.list same_tmp.list | uniq -u > zipfile_patch.list
fi





NewFileDate=`date +%y%m%d`
echo "begin zip..."
rm -f ./installer/main.zip
cat zipfile_patch.list | zip -q ./installer/main.zip -@
if [[ $?==0 ]]; then
  :
else
  exit -1
fi

rm -f ./installer/main.pkg
./ParaEngineServer 'bootstrapper="script/shell_loop_encryptzipfiles.lua"'
pid=`ps ax|grep ParaEngineServer.*shell_loop_encryptzipfiles|cut -d" " -f1`

sleep 2

rm -f /mnt/installer/main$NewFileDate.pkg
rm -f /mnt/installer/zipfile_patch.list
mv ./installer/main.pkg ./installer/main$NewFileDate.pkg
mv ./installer/main.zip ./installer/main$NewFileDate.zip
cp ./installer/main$NewFileDate.pkg /mnt/installer/.

listfile="Aries_installer_v1.txt"
final_file=`sed -nr "s/^(.* )(\S*main[0-9]+\.pkg)(.*)/\2/p" /mnt/ParaEngineSDK/$listfile`
cp -f ./installer/main$NewFileDate.pkg /mnt/ParaEngineSDK/$final_file
echo final file is generated at /mnt/ParaEngineSDK/$final_file as in Aries_installer_v1.txt from /mnt/ParaEngineSDK/installer/main$NewFileDate.pkg

rm -f exclude*.list
rm -f same_tmp.list

if [ -z $pid ];then
  :
else
  killall -9 ParaEngineServer
fi
