#!/bin/bash

svn update /opt/packages --username YDD --password YDDParaEngine
svn update /opt/script  --username YDD --password YDDParaEngine |grep revision|awk -F"revision " '{print $2}'|cut -d. -f1 > svn_script_base.ver
svn update /opt/_emptyworld  --username YDD --password YDDParaEngine

cd /var/lib/hudson/jobs/client_pkg_patch
rm -rf bin
rm -f log.txt
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
  if [ $i -gt 30 ];then
    echo "sleeping too long" >> log.txt
    tail log.txt
    exit 1
  fi
done

echo "sleep $i seconds" >> log.txt


conf_file="packages/redist/main_script-1.0.txt"
sed -n '/--------------------/,$p' "$conf_file" | grep -v "^--" | grep -v "\[exclude*" | sed -e 's/[\t ]*$//g' > all_tmp0.list
sed -n '/--------------------/,$p' "$conf_file" | grep -v "^--" | grep -v "\[exclude*" | sed -e 's/[\t ]*$//g' | grep -v "*" | tr -s '\r\n' '\n' > forceinclude.list

grep "\[exclude\]" "$conf_file" | grep -v "^--" | sed -e 's/\[exclude\]//g'| sed -e 's/[\t ]*$//g' > exclude_tmp0.list
grep "\[exclude1\]" "$conf_file" | grep -v "^--" | sed -e 's/\[exclude1\]//g'| sed -e 's/[\t ]*$//g' > exclude1_tmp0.list
grep "\[exclude3\]" "$conf_file" | grep -v "^--" | sed -e 's/\[exclude3\]//g'| sed -e 's/[\t ]*$//g' > exclude3_tmp0.list

rm -f all_tmp1.list
rm -f exclude_tmp1.list
rm -f zipfile_all.list
while read xx0
do
  echo $xx0
  spath=`dirname $xx0`/
  sname=`basename $xx0| tr -s '\r\n' '\n'`
  if [ -d "$spath" ];then
    find "$spath" -iname "$sname" |grep -v ".svn" >> all_tmp1.list
  fi
done < all_tmp0.list

while read xx
do
  echo $xx
  spath=`dirname $xx`/
  sname=`basename $xx| tr -s '\r\n' '\n'`
  if [ -d "$spath" ];then
    find "$spath" -iname "$sname" |grep -v ".svn" >> exclude_tmp1.list
  fi
done < exclude_tmp0.list

while read xx
do
  echo $xx
  spath=`dirname $xx`/
  sname=`basename $xx| tr -s '\r\n' '\n'`
  if [ -d "$spath" ];then
    find "$spath" -maxdepth 1 -iname "$sname" |grep -v ".svn" >> exclude_tmp1.list
  fi
done < exclude1_tmp0.list

while read xx
do
  echo $xx
  spath=`dirname $xx`/
  sname=`basename $xx| tr -s '\r\n' '\n'`
  if [ -d "$spath" ];then
    find "$spath" -maxdepth 3 -iname "$sname" |grep -v ".svn" >> exclude_tmp1.list
  fi
done < exclude3_tmp0.list

# keep force include files
sort exclude_tmp1.list |uniq > exclude_tmpx.list
sort forceinclude.list exclude_tmpx.list | uniq -d > same_in.list
sort exclude_tmpx.list same_in.list | uniq -u > exclude_tmp1.list

# exclude files
sort all_tmp1.list |uniq > all_tmpx.list
sort all_tmpx.list exclude_tmp1.list | uniq -d > same_tmp.list
sort all_tmpx.list same_tmp.list | uniq -u > zipfile_all.list

#exit

#gen main.pkg
echo "begin zip..."
rm -f ./installer/main.zip
cat zipfile_all.list | zip -q ./installer/main.zip -@
if [[ $?==0 ]]; then
  :
else
  exit -1
fi
rm -f ./installer/main.pkg
./ParaEngineServer 'bootstrapper="script/shell_loop_encryptzipfiles.lua"'
pid=`ps ax|grep ParaEngineServer.*shell_loop_encryptzipfiles|cut -d" " -f1`

sleep 2
cp ./installer/main.* /var/lib/hudson/jobs/client_pkg/workspace/.
cp zipfile_all.list /var/lib/hudson/jobs/client_pkg/workspace/.
echo main.pkg generated successfull!!

cat exclude_tmp1.list | zip -q ./installer/main.zip -@
./ParaEngineServer 'bootstrapper="script/shell_loop_encryptzipfiles.lua"'
pid=`ps ax|grep ParaEngineServer.*shell_loop_encryptzipfiles|cut -d" " -f1`

sleep 2
mv ./installer/main.zip ./installer/main_Aries_pipeline.zip
mv ./installer/main.pkg ./installer/main_Aries_pipeline.pkg
cp ./installer/main_Aries*.* /var/lib/hudson/jobs/client_pkg/workspace/.
cp exclude_tmp1.list /var/lib/hudson/jobs/client_pkg/workspace/zipall_Aries_pipeline.list
echo main_Aries_pipeline.pkg generated successfull!!

rm -f all_tmp*.list
rm -f exclude*.list
rm -f same_*.list
rm -f ./installer/main_Aries*.*

cp /var/lib/hudson/jobs/client_pkg/workspace/main.pkg ./installer/.
killall -9 ParaEngineServer
