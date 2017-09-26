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

/home/ftpasset ==== server.228:/home/upload/asset/

as 228 ftp:
> apt install vsftpd

useradd -s /bin/false -m ftpasset
passwd ftpasset
> ftpparaengine

if can't login with ftpasset user, try this:
https://askubuntu.com/questions/413677/vsftpd-530-login-incorrect



config /etc/vsftpd.conf
> thanks https://www.benscobie.com/fixing-500-oops-vsftpd-refusing-to-run-with-writable-root-inside-chroot/
uncomment
> chroot_local_user=YES
add
> allow_writeable_chroot=YES


> https://stackoverflow.com/questions/11304895/how-to-scp-a-folder-from-remote-to-local

sudo -u ftpasset rm -rf /home/ftpasset/.* /home/ftpasset/*
sudo -u ftpasset scp -r root@server.228:/home/upload/asset/. /home/ftpasset/


----

/var/www/assetdownload/ === server.228:/var/www/assetdownload/

as 228 http:
> apt install apache2

config /etc/apache2/sites-enabled/000-default.conf
change root
```
DocumentRoot /var/www/
```
sudo service apache2 restart

sudo mkdir /var/www/assetdownload
sudo chown www-data:www-data -R /var/www
sudo -u www-data scp -r root@server.228:/var/www/assetdownload/.  /var/www/assetdownload/
