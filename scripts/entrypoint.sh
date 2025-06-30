#!/bin/sh
/usr/sbin/sshd -D &
su dockeruser -c "vncserver :1 -geometry 1920x1080"
su dockeruser -c "/home/dockeruser/noVNC/utils/novnc_proxy --vnc localhost:5901 --listen 6080"
