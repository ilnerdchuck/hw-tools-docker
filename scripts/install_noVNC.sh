#!/bin/bash
git clone https://github.com/novnc/noVNC /home/dockeruser/noVNC

mkdir $USER_HOME/.vnc
cp /$SCRIPTS_DIR/xstartup $USER_HOME/.vnc/
chmod +x $HOME/.vnc/xstartup

echo $USER_PWD | vncpasswd -f >$HOME/.vnc/passwd
chmod 0600 $HOME/.vnc/passwd
