#!/bin/sh
su dockeruser -c "vncserver :1 -geometry 1920x1080"
su dockeruser -c "nohup /home/dockeruser/noVNC/utils/novnc_proxy --vnc localhost:5901 --listen 6080 &"

# nohup $HOME/noVNC/utils/novnc_proxy --vnc localhost:5901 --listen 6080 & > noVNC_log.txt
