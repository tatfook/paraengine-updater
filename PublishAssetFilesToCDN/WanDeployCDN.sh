#!/usr/bin/expect

if {$argc!=1} {
  puts stderr "Usage: $argv0 kids|teen|assets|haqi1web|haqi2web"
    exit 1
}

set cmd_prompt "]#|~]?"
set svrtype [lindex $argv 0]

if {"$svrtype" == "kids"} {
  set cmdstr  "rsync_core.sh"
} elseif {"$svrtype" == "teen"} {
  set cmdstr "rsync_teencore.sh"
} elseif {"$svrtype" == "assets"} {
  set cmdstr "rsync_asset.sh"
} elseif {"$svrtype" == "haqi1web"} {
  set cmdstr "rsync_haqi1web.sh"
} elseif {"$svrtype" == "haqi2web"} {
  set cmdstr "rsync_haqi2web.sh"
}

#spawn ssh -p56000 taomee@183.60.209.140
#spawn ssh -p56000 taomee@114.80.98.36
spawn ssh -p22 root@121.14.117.252

set timeout 300
expect {
  -re "Are you sure you want to continue connecting (yes/no)?" {
    send "yes\r"
  } -re "assword:" {
#send "ta0mee!@#123\r"
    send "Tf.300134\r"
  } -re "Permission denied, please try again." {
    exit
  } -re "Connection refused" {
    exit
  } timeout {
    exit
  } eof {
    exit
  }
}

expect {
  -re "assword:" {
#send "ta0mee!@#123\r"
    send "Tf.300134\r"
  }
  -re $cmd_prompt {
    send "\r"
  }
}

expect {
  -re $cmd_prompt {
#     send "sudo /root/pubscript/$cmdstr \r"
    send "/root/pubscript/$cmdstr \r"
  }
}

sleep 10

expect {
  -re "ParaEngineCDN*" {
    send "exit\r"
  }
}

exit
