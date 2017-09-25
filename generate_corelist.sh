#!/bin/bash

teentag=""
if [ $# -eq 1 ]; then
    teentag=$1
fi

if [ "$teentag" == "teen" ]; then
    listfile="Aries_installer_teen.txt"
    updatelist="coreupdate_teen.list"
    needlist="core_need_teen.list"
else
    # jump here
    listfile="Aries_installer_v1.txt"
    updatelist="coreupdate.list"
    needlist="core_need.list"
fi

rm -f $needlist

cd /opt/hudson_conf/ci_shell/Client

# extract all lines
sed -n '/# Aries Client Core File List/,/# Post setup/p' ParaEngineSDK/$listfile |
    sed -e 's/^[\t ]*//g' -e '/^[#;]/d' -e '/^[[:space:]]*$/d' -e 's/\\/\\\\/g' -e 's/\$/\\$/g' >$updatelist

remotePath=""
while read line; do
    testPath=$(echo $line | grep -E "^SetOutPath")

    # start with SetOutPath
    if [ ! -z "$testPath" ]; then
        remotePath=""

        remotePath0=$(echo $line | sed -e 's/SetOutPath \\$INSTDIR//g' -e '/^[[:space:]]*$/d')
        # sub dir in \$INSTDIR
        if [ ! -z "$remotePath0" ]; then
            # sub \\ as /,  's#\\\\#/#g'
            temp_path=$(echo $remotePath0 | sed -e 's/\\///g' -e 's/[ \t]*//g')
            # string length
            len_0=${#temp_path}
            # 6666666
            ((len_0--))
            # strip first /?
            remotePath=$(echo $temp_path | cut -c 2-$len_0 | tr A-Z a-z)
        fi
    else
        # not start with SetOutPath
        testFoname=$(echo $line | grep -E "^File /oname")
        # start with File /oname
        if [ ! -z "$testFoname" ]; then
            # File /oname=commands.xml "config\\Aries.commands.xml"                                                                   ;pefile=0
            # remotefile=mainstate.lua
            # locatefile=config/Aries.commands.xml
            # filetype=0
            remotefile=$(echo $line | awk -F" " '{print $2}' | cut -d= -f2 | sed -e 's/\\\\/\//g' | tr A-Z a-z)
            localfile=$(echo $line | awk -F" " '{print $3}' | cut -d'"' -f2 | sed -e 's/\\\\/\//g')
            filetype=$(echo $line | awk -F" " '{print $4}' | awk -F"=" '{printf("%d",$2)}')

            if [ -z "$remotePath" ]; then
                # root $INSTDIR
                echo "$localfile,${remotefile}._P_E_$filetype" >>$needlist
            else
                # not root $INSTDIR
                echo "$localfile,$remotePath/${remotefile}._P_E_$filetype" >>$needlist
            fi
        else
            # not start with File /oname
            # check "/r" to search files in recursion subdirectories
            testFr=$(echo $line | grep -E "^File /r ")
            # if File /r
            if [ ! -z "$testFr" ]; then
                # File /r config\\Aries                                                                   ;pefile=0
                # localfiles=config/Aries
                # filetype=0
                # remotefiles=(`ls ParaEngineSDK/config/Aries`)
                localfiles=$(echo $line | awk -F" " '{print $3}' | sed -e 's/\\\\/\//g')
                filetype=$(echo $line | awk -F" " '{print $4}' | awk -F"=" '{printf("%d",$2)}')
                remotefiles=($(find ParaEngineSDK/$localfiles))
                # store remotefile list to needlist
                for tfile in ${remotefiles[@]}; do
                    localfile=$(echo $tfile | sed -e 's/ParaEngineSDK\///')
                    remotefile=$(echo $localfile | tr A-Z a-z)
                    echo "$localfile,${remotefile}._P_E_$filetype" >>$needlist
                done
            fi

            # normal lines
            testFile=$(echo $line | grep -E "^File" | grep -v "File /oname")
            if [ ! -z "$testFile" ]; then
                # File sqlite.dll                                                     ;pefile=0
                # remotefile=sqlite.dll
                # localfile=sqlite.dll
                # filetype=0
                remotefile=$(echo $line | awk -F" " '{print $2}' | sed -e 's/\\\\/\//g' | tr A-Z a-z)
                localfile=$remotefile
                filetype=$(echo $line | awk -F" " '{print $3}' | awk -F"=" '{printf("%d",$2)}')
                echo "$localfile,${remotefile}._P_E_$filetype" >>$needlist
            fi
        fi
    fi
done <$updatelist

rm -f $updatelist
