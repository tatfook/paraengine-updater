#!/bin/bash

# first, it pull svn code from svn://svn.paraengine.com/script/trunk/
# this repo should be npl_packages/paracraft (like main packages)

# ./get_pkg_patch.sh   basever(number) | zipfile_patch.list

# parse params
if [ $# -eq 0 ]; then
    basever=9857
else
    testp=$(echo $1 | grep -E "^[0-9]+$")
    if [[ $# -eq 1 && ! -z "$testp" ]]; then
        basever=$1
    else
        if [ "$1" != "zipfile_patch.list" ]; then
            echo "Wrong parameters! Usage: $(basename $0)  basever|zipfile_patch.list"
            exit 1
        else
            zippatch_list=$1
        fi
    fi
fi
unset testp

# vars:
#   - basever
#   - zippatch_list

# mount ParaEngineSDK from 241
mounttest=$(mount | grep "/mnt/ParaEngineSDK")
if [ -z "$mounttest" ]; then
    /bin/mount -t cifs -o password=paraengine,uid=108,gid=65534 //192.168.0.241/installer /mnt/installer
    /bin/mount -t cifs -o password=paraengine //192.168.0.241/Texture /mnt/Texture
    /bin/mount -t cifs -o password=paraengine //192.168.0.241/model /mnt/model
    /bin/mount -t cifs -o password=paraengine //192.168.0.241/character /mnt/character
    /bin/mount -t cifs -o password=paraengine,uid=108,gid=65534 //192.168.0.241/ParaEngineSDK /mnt/ParaEngineSDK
fi

#svn update /opt/packages --username YDD --password YDDParaEngine
#svn update /opt/script  --username YDD --password YDDParaEngine |grep revision|awk -F"revision " '{print $2}'|cut -d. -f1 > svn_script.ver
#svn update /opt/_emptyworld  --username YDD --password YDDParaEngine

cd /var/lib/hudson/jobs/client_pkg_patch
rm -rf bin
rm -f log.txt

# ParaEngineServer links to /opt/NPLRuntime/ParaWorld/bin64/ParaEngineServer
# npl run a lua script
# it load ("(gl)script/installer/BuildParaWorld.lua");
# script links to ./workspace/script_svn/script (svn repo)
#
# file path is ./workspace/script_svn/script/installer/BuildParaWorld.lua
# commonlib.BuildParaWorld.CompileNPLFiles()
./ParaEngineServer 'bootstrapper="script/shell_compile.lua"'

# wait shell_compile.lua run to the end
sleep 1
i=1
grep "Compile END" log.txt
end_result=$?
echo "result is $end_result" >>log.txt
while [ $end_result -ne 0 ]; do
    sleep 1
    i=$(expr $i + 1)
    grep "Compile END" log.txt >/dev/null
    end_result=$?
    echo "sleeping $i seconds"
    if [ $i -gt 50 ]; then
        echo "sleeping too long" >>log.txt
        exit 1
    fi
done

echo "sleep $i seconds" >>log.txt

# begins
if [ -z "$zippatch_list" ]; then
    # if param is base version not zippatch_list
    # packages links to ./workspace/script_svn/packages(svn repo)
    #
    # main_script-1.0.txt
    # --
    # [exclude]
    # [exclude1]
    # [exclude3]
    # filepath
    #
    conf_file="packages/redist/main_script-1.0.txt"

    grep "\[exclude\]" "$conf_file" | grep -v "^--" | sed -e 's/\[exclude\]//g' | sed -e 's/[\t ]*$//g' >exclude_tmp0.list
    grep "\[exclude1\]" "$conf_file" | grep -v "^--" | sed -e 's/\[exclude1\]//g' | sed -e 's/[\t ]*$//g' >exclude1_tmp0.list
    grep "\[exclude3\]" "$conf_file" | grep -v "^--" | sed -e 's/\[exclude3\]//g' | sed -e 's/[\t ]*$//g' >exclude3_tmp0.list

    rm -f exclude_tmp1.list

    # hack here
    # path in find must end with /
    # name can contains /
    # eg. find script/ -name *.lua
    # not!!! find . -name script/*.lua
    #
    # export all exclude file paths to a list file
    while read xx; do
        spath=$(dirname $xx)/
        sname=$(basename $xx | tr -s '\r\n' '\n')
        find "$spath" -name "$sname" >>exclude_tmp1.list
    done <exclude_tmp0.list

    while read xx; do
        spath=$(dirname $xx)/
        sname=$(basename $xx | tr -s '\r\n' '\n')
        find "$spath" -maxdepth 1 -iname "$sname" >>exclude_tmp1.list
    done <exclude1_tmp0.list

    while read xx; do
        spath=$(dirname $xx)/
        sname=$(basename $xx | tr -s '\r\n' '\n')
        find "$spath" -maxdepth 3 -iname "$sname" >>exclude_tmp1.list
    done <exclude3_tmp0.list

    # exclude_tmp1.list saves all files should to be excluded

    # exclude all .svn paths
    grep -v ".svn" exclude_tmp1.list | sort | uniq >exclude_tmp0.list

    # diff with base version and save all changed files
    svn diff --summarize --username ci --password ci1234567 -r $basever svn://svn.paraengine.com/script/trunk/script | sed -rn 's/.*svn:.*script\/trunk\/(.*)/\1/p' >changelist.txt

    # force include files(abs path, no *)
    sed -n '/--------------------/,$p' "$conf_file" | grep -v "^--" | grep -v "\[exclude*" | sed -e 's/[\t ]*$//g' | grep -v "*" | tr -s '\r\n' '\n' >forceinclude.list

    # config dir links to /mnt/ParaEngineSDK/config
    # get all config files here
    sed -n '/--------------------/,$p' "$conf_file" | grep -v "^--" | grep -v "\[exclude*" | sed -e 's/[\t ]*$//g' | grep "config/" >configtemp.txt
    rm -f configfiles.list
    while read xx0; do
        path=$(dirname $xx0)/
        name=$(basename $xx0 | tr -s '\r\n' '\n')
        find "$path" -iname "$name" >>configfiles.list
    done <configtemp.txt

    # compare with old config files, get patch config list
    basecfg_dir="/opt/config_bak/config"
    rm -f configpatch.list
    while read xx0; do
        xx=$(echo "$xx0" | sed -e 's/config\///')
        if [ -f "$basecfg_dir/$xx" ]; then
            line_ending=""
            if [ "${xx: -4}" == ".xml" ]; then
                line_ending="--strip-trailing-cr"
            fi
            # if diff return 0, two files are same
            diff -q "$basecfg_dir/$xx" "$xx0" $line_ending >/dev/null
            if [ $? -ne 0 ]; then
                echo $xx0 >>configpatch.list
            fi
        else
            echo $xx0 >>configpatch.list
        fi
    done <configfiles.list

    # merge all patch files
    cat configpatch.list >>changelist.txt

    rm -f zipfile_patch.list
    rm -f patch_tmp1.list
    rm -f exclude_tmpx.list

    # add all changed files to patch_tmp1.list, Fixed force include *.lua
    # by LiXizhi 2015.7.19
    grep -v "^--" "$conf_file" | grep -v "\[exclude*" | sed -e 's/[\t ]*$//g' | grep "\*\.lua" | sed "s/\*\.lua//" | tr -s '\r\n' '\n' >forceincludelua.list

    function is_lua_file_forceinclude() {
        filename="$1"
        while read linetext; do
            if [ "${filename#${linetext}}" != "$filename" ]; then
                return 0
            fi
        done <forceincludelua.list
        return 1
    }

    while read linetext; do
        script_regx="^script.*lua$"
        if [[ $linetext =~ $script_regx ]]; then
            if (is_lua_file_forceinclude "$linetext"); then
                echo $linetext >>patch_tmp1.list
            else
                echo "bin/${linetext%lua}o" >>patch_tmp1.list
            fi
        else
            echo $linetext >>patch_tmp1.list
        fi
    done <changelist.txt

    # keep force include files
    sort exclude_tmp0.list | uniq >exclude_tmpx.list
    sort forceinclude.list exclude_tmpx.list | uniq -d >same_in.list
    sort exclude_tmpx.list same_in.list | uniq -u >exclude_tmp0.list

    # exclude files
    sort patch_tmp1.list | uniq >patch_tmp0.list
    sort patch_tmp0.list exclude_tmp0.list | uniq -d >same_tmp.list
    sort patch_tmp0.list same_tmp.list | uniq -u >zipfile_patch.list
fi

echo "begin zip..."

NewFileDate=$(date +%y%m%d)

# store patch file list as a zip
rm -f ./installer/main.zip
cat zipfile_patch.list | zip -q ./installer/main.zip -@
if [[ $?==0 ]]; then
    :
else
    exit -1
fi

# generate mainxxxxx.pkg
rm -f ./installer/main.pkg
./ParaEngineServer 'bootstrapper="script/shell_loop_encryptzipfiles.lua"'

pid=$(ps ax | grep ParaEngineServer.*shell_loop_encryptzipfiles | cut -d" " -f1)
sleep 2

# installer241 links to /mnt/installer
rm -f ./installer241/main$NewFileDate.pkg
rm -f ./installer241/zipfile_patch.list
mv ./installer/main.pkg ./installer/main$NewFileDate.pkg
mv ./installer/main.zip ./installer/main$NewFileDate.zip
cp ./installer/main$NewFileDate.pkg /var/lib/hudson/jobs/client_pkg_patch/workspace/.
cp ./installer/main$NewFileDate.zip /var/lib/hudson/jobs/client_pkg_patch/workspace/.
cp ./installer/main$NewFileDate.pkg ./installer241/.

# copy mainxxxx.pkg to cifs
listfile="Aries_installer_v1.txt"
final_file=$(sed -nr "s/^(.* )(\S*main[0-9]+\.pkg)(.*)/\2/p" /mnt/ParaEngineSDK/$listfile)
cp -f ./installer/main$NewFileDate.pkg /mnt/ParaEngineSDK/$final_file

echo final file is generated at /mnt/ParaEngineSDK/$final_file as in Aries_installer_v1.txt from /mnt/ParaEngineSDK/installer/main$NewFileDate.pkg

# store zippatch_list to workspace
cp zipfile_patch.list /var/lib/hudson/jobs/client_pkg_patch/workspace/.

# make some clean things
rm -f exclude*.list
rm -f same_tmp.list

# kill all npl processes
if [ -z $pid ]; then
    :
else
    killall -9 ParaEngineServer
fi
