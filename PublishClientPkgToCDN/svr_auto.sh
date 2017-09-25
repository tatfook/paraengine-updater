#!/usr/bin/expect

if {$argc!=3} {
  puts stderr "Usage: $argv0 ipaddr loginpass cmd"
    exit 1
}

set ip [lindex $argv 0]
set cmd_prompt "]#|~]?"
set loginpass [lindex $argv 1]
set cmd [lindex $argv 2]

spawn ssh root@$ip

set timeout 300
expect {
  -re "Are you sure you want to continue connecting (yes/no)?" {
    send "yes\r"
  } -re "assword:" {
    send "$loginpass\r"
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
    send "$loginpass\r"
  }
  -re $cmd_prompt {
    send "\r"
  }
}

expect {
  -re $cmd_prompt {
    send "$cmd\r"
  }
}

sleep 10

expect {
  -re "Para*" {
    send "exit\r"
  }
}
exit
