# insight map

## servers

### 228

server 228 host ftp service and http service.

http:
- static: /var/www/***
- cgi: /usr/lib/cgi-bin/***


ftp:
different user has different configure
- config dir: /etc/vsftpd_user_conf/**username**

### 200

server 200 host svn and perforce

svn:
-



## sumulation

/home/ftpasset/ ==== server.228:/home/upload/asset/
/home/ftpuser1/ ==== server.228:/home/upload/prog/

as 228 ftp:
> apt install vsftpd

sudo useradd -s /bin/false -m ftpasset
sudo passwd ftpasset
> ftpparaengine
sudo useradd -s /bin/false -m ftpuser1
sudo passwd ftpuser1
> ftpparaengine

if can't login with ftpasset user, try this:
https://askubuntu.com/questions/413677/vsftpd-530-login-incorrect



config /etc/vsftpd.conf
> thanks https://www.benscobie.com/fixing-500-oops-vsftpd-refusing-to-run-with-writable-root-inside-chroot/
uncomment
> chroot_local_user=YES
add
> allow_writeable_chroot=YES


https://ubuntuforums.org/showthread.php?t=833829
uncomment for PUT instructions working
> write_enable=YES


> https://stackoverflow.com/questions/11304895/how-to-scp-a-folder-from-remote-to-local

sudo -u ftpasset rm -rf /home/ftpasset/.* /home/ftpasset/*
sudo -u ftpasset scp -r root@server.228:/home/upload/asset/. /home/ftpasset/
sudo -u ftpuser1 rm -rf /home/ftpuser1/.* /home/ftpuser1/*
sudo -u ftpuser1 scp -r root@server.228:/home/upload/prog/. /home/ftpuser1/


----

/var/www/asset/ === server.228:/var/www/asset/
/var/www/assetdownload/ === server.228:/var/www/assetdownload/
/var/www/coredownload/ === server.228:/var/www/coredownload/
/var/www/prog/ === server.228:/var/www/prog/

as 228 http:
> apt install apache2

config /etc/apache2/sites-enabled/000-default.conf
change root
```
DocumentRoot /var/www/
```
sudo service apache2 restart

sudo mkdir /var/www/asset
sudo mkdir /var/www/assetdownload
sudo mkdir /var/www/coredownload
sudo mkdir /var/www/prog
sudo mkdir /var/www/refresh_time
sudo chown www-data:www-data -R /var/www
sudo -u www-data scp -r root@server.228:/var/www/asset/.  /var/www/asset/
sudo -u www-data scp -r root@server.228:/var/www/assetdownload/.  /var/www/assetdownload/
sudo -u www-data scp -r root@server.228:/var/www/coredownload/.  /var/www/coredownload/
sudo -u www-data scp -r root@server.228:/var/www/prog/.  /var/www/prog/
sudo -u www-data scp -r root@server.228:/var/www/refresh_time/.  /var/www/refresh_time/


---

client_pkg_patch/config ==== server.25:/opt/config_bak/config


cd ~/project/paraengine-updater
mkdir ./client_pkg_patch/config/
scp -r root@server.25:/opt/config_bak/config/.  ./client_pkg_patch/config/

-----

client_pkg_patch/installer === server.25:/var/lib/hudson/jobs/client_pkg_patch/installer

cd ~/project/paraengine-updater
mkdir ./client_pkg_patch/installer/
scp -r root@server.25:/var/lib/hudson/jobs/client_pkg_patch/installer/.  ./client_pkg_patch/installer/

## 241 and 242

每一个jenkins slave上面，都mount了241,242的共享文件夹

最近搬迁之后暴露一个问题，打包构建之后，版本回退到很久以前

定位了很久才发现，原来241,242两台机器早就废弃不用，并将其ip绑定到200机器上

如何查看共享文件夹：

控制面板-> 搜索"计算机管理"， 在系统工具->共享文件夹下，就可以看到所有的共享列表

路径：  ParaEngineSDK === D:\hudsonworkspace\workspace\asset_ABupdate\paracraft

这个路径是最开始进行 asset_ABupdate的目录路径


point:

在windows上，启动映射网络驱动器，如果使用的路径是本地的路径，其为映射虚拟磁盘；如果映射的网络地址非本机地址，其为网络驱动器；

查看映射虚拟磁盘
> subst

查看映射网络驱动器
> net use

查看自己的主机名
> set computername
