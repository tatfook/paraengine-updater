# paraengine-updater

A npl mod to update paraengine

## how old ci do

### servers

192.168.0.

ci master: 25
ci slaves: 200(win server), 224, 240 

### phase

#### assetupdate

http://192.168.0.25:8080/view/%E5%84%BF%E7%AB%A5%E7%89%88ClientBuild/job/assetupdate/configure

running on 240, update from svn and run script

svn is hosted on 200

svn address:  svn://192.168.0.200/hudson_conf

```
#/bin/bash
svn update --username svr233 --password svr233ParaEngine /opt/hudson_conf/ci_shell/Client
cd /opt/hudson_conf/ci_shell/Client
./AssetUpdate.sh
```

what AssetUpdate.sh does?

pwd: /opt/hudson_conf/ci_shell/Client

1. svn update /opt/packages
user: YDD
addr: svn://192.168.0.200/script/trunk/packages

2. copy `/opt/packages/redist/_assetmanifest.ftp.uploader.txt` to assetmanifest.txt

rules of this file:

    -- comments

    -- exclude file list                                                                                                         
    -- [exclude]/aaa/bbb/*.* ; exclude all files from directory /aaa/bbb/, include all subdirectory under it          
    -- [exclude1]/aaa/bbb/*.x ; exclude files like *.x only in directory  /aaa/bbb/ , not include any subdirectory under it      
                                                                                                                                 
    -- search file list                                                                                                          
    -- [search]/aaa/bbb/*.* ; include all files from directory  /aaa/bbb/ , include all subdirectory under it           
    -- [search1]/aaa/bbb/*.x ; include all files like *.x only in directory  /aaa/bbb/ , not include any subdirectory under it   

    /aaa/bbb/run8.dds, specific paths
                                                                                                                             
ParaEngineSDK link to dir /mnt/ParaEngineSDK, /mnt/ParaEngineSDK mounted from //192.168.0.241/ParaEngineSDK

merge a ftp_all.txt

3. download ftpsvrlist0.txt

wget http://192.168.0.228/assetdownload/list/ftpsvrlist0.txt

server 228 running apache, file path: /var/www/assetdownload/list/ftpsvrlist0.txt

4. upload files to 228 ftp


5. call 228 cgi-bin/upload_asset2.sh

server: 228

path: /usr/lib/cgi-bin/upload_asset2.sh


#### client_pkg_patch

running on 25

job dir: /var/lib/hudson/jobs/client_pkg_patch

svn update first, from `svn.paraengine.com/script/thunk` to job dir `script_svn`

run get_pkg_patch.sh 17798

inside:

mount 241 dir to /mnt/*

#### client_pkg_

running on 25

similar with client_pkg_patch

run get_pkg_full.sh script

#### core_update_







































