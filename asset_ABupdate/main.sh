#!/usr/bin/env bash

# sync AB to get the newest assets and client programs.

# execute on server 200, windows server


# perfoce update
# p4 -p tcp:192.168.0.200:1666 -u ci -P ci1234567 sync

# perforce server is serve in 200, open P4V program and connect 192.168.0.200:1666
#
# user: ci, workspace: ci_241, view map:
#
# ```
# //paracraft/... //ci_241/paracraft/...
# -//paracraft/....psd //ci_241/paracraft/....psd
# -//paracraft/....max //ci_241/paracraft/....max
# ```
#
# strange thing is that perforce is served in 200
#
# serve path: D:\p4server\paracraft
#
# this job use perforce terminal client to update in the same machine.
#
# client workspace path: D:\hudsonworkspace\workspace\asset_ABupdate\paracraft


echo "===================="
echo "phase asset_ABupdate"
echo "===================="

exit 0
