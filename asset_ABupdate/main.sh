#!/usr/bin/env bash
#
# orininal
# sync AB to get the newest assets and client programs.
# execute on server 200, windows server
# serve path: D:\p4server\paracraft


# perforce server is serve in 200, open P4V program and connect 10.27.2.200:1666
#
# user: ci, workspace: ci_241, view map:
#
# ```
# //paracraft/... //ci_241/paracraft/...
# -//paracraft/....psd //ci_241/paracraft/....psd
# -//paracraft/....max //ci_241/paracraft/....max
# ```
# client workspace path: D:\hudsonworkspace\workspace\asset_ABupdate\paracraft


echo "===================="
echo "phase asset_ABupdate"
echo "===================="

# how to use p4
# '-p tcp:10.27.2.200:1666 -u ci -P ci1234567' is always needed

# add new client
#   p4 client [name]
# error:
#  Can't add client - over license quota.
#  Try deleting old clients with 'client -d'.
#  License count: 20 clients used of 20 licensed
#
# list existed clients
#   p4 clients
#
# show&modify client config
#   p4 -c ci_241 client
#
# delete a client (need admin user)
#   p4 client -df ci_242
#
# add a new client(open vim and modify config file, only need to save it)
#   p4 client
#
# sync
# FIXME there are some file names contains chinese characters that are displayed unnormally
p4 -p tcp:10.27.2.200:1666 -u ci -P ci1234567 -c paraengine_updater sync

exit 0
