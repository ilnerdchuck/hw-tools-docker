# -----------------------------------------------------------------------------
# Dockerfile for HE Developing
# Author: Francesco Mignone - IlNerdChuck
# Created: 24-06-2025
# Description: A Docker containing most of the tools needed to develop HDL
#              languages for simulation and synthesis
# -----------------------------------------------------------------------------
# Use the Ubuntu 16:04 base image
FROM ubuntu:20.04 AS ubuntu-stage

# LABEL about the custom image
LABEL maintainer="Francesco Mignone - IlNerdChuck"
LABEL version="0.1"
LABEL description="This is a custom Docker Image to gather hardware developing tools."
# Sets the timezone
ENV TZ=EU

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ARG DEBIAN_FRONTEND=noninteractive
# Update packages and install SSH server
RUN apt update && apt-get install -y openssh-server sudo

# Update packages and install SSH server
# RUN apt-get update && apt install -y ubuntu-desktop

# gnome-panel \
# gnome-settings-daemon \
# gnome-terminal \
# RUN apt install -y \
#     tightvncserver \
#     metacity \
#     xfce4 \
#     xfce4-terminal \
#     xfce4-goodies \
#     nautilus \
#     git \
#     nano && apt-get clean

RUN apt-get remove ubuntu-gnome-desktop
RUN apt-get remove gnome-shell
RUN apt-get remove firefox
RUN apt-get remove libreoffice

RUN apt update
RUN apt install -y \
    tightvncserver \
    metacity \
    ubuntu-mate-desktop \
    nautilus \
    git \
    nano && apt-get clean

# Create the SSH directory and configure permissions
RUN mkdir /var/run/sshd

WORKDIR /startup

ENV USER_NAME=dockeruser
ENV USER_PWD=password
# setup scripts
COPY scripts /startup/scripts
RUN chmod +rx /startup/scripts/*
ENV SCRIPTS_DIR=/startup/scripts

# Add a new user 'dockeruser' and set a password
RUN useradd -m -s /bin/bash dockeruser && echo 'dockeruser:password' | chpasswd

# Optional: Add the user to the sudoers to allow administrative actions
RUN echo 'dockeruser ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/dockeruser && chmod 0440 /etc/sudoers.d/dockeruser

# Enable password authentication in the SSH configuration
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Optional: Disable root login via SSH
RUN echo "PermitRootLogin yes" >>/etc/ssh/sshd_config

RUN chown dockeruser:dockeruser /startup/scripts/*

# Set the correct sh dash has problems with source
# RUN ln -s bash /bin/sh.bash
# RUN mv /bin/sh.bash /bin/sh

RUN bash $SCRIPTS_DIR/pre_install.sh

FROM ubuntu-stage AS vsim-stage

WORKDIR /tmp

RUN dpkg --add-architecture i386
RUN apt-get update
RUN apt-get install -y libc6:i386 libncurses5:i386 libstdc++6:i386 lib32ncurses6 libxft2 libxft2:i386 libxext6 libxext6:i386
# For ubuntu 24.04, but the GUI isn't working
# RUN apt-get install -y libc6:i386 libncurses6:i386 libstdc++6:i386 lib32ncurses6 libxft2 libxft2:i386 libxext6 libxext6:i386

# RUN dpkg --add-architecture i386
# RUN apt-get update
# RUN apt-get install -y gcc-multilib g++-multilib
# RUN apt-get install -y lib32z1 lib32stdc++6 lib32gcc1
# RUN apt-get install -y expat:i386 fontconfig:i386 libfreetype6:i386 libexpat1:i386 libc6:i386 libgtk-3-0:i386
# RUN apt-get install -y libcanberra0:i386 libpng12-0:i386 libice6:i386 libsm6:i386 libncurses5:i386 zlib1g:i386
# RUN apt-get install -y libx11-6:i386 libxau6:i386 libxdmcp6:i386 libxext6:i386 libxft2:i386 libxrender1:i386
# RUN apt-get install -y libxt6:i386 libxtst6:i386

# COPY ./ModelSimSetup-20.1.1.720-linux.run .
RUN wget https://download.altera.com/akdlm/software/acdsinst/20.1std.1/720/ib_installers/ModelSimSetup-20.1.1.720-linux.run
RUN chmod +x ModelSimSetup-20.1.1.720-linux.run
RUN mkdir /opt/intelFPGA
RUN chown dockeruser:dockeruser -R /opt/intelFPGA

USER dockeruser
RUN ./ModelSimSetup-20.1.1.720-linux.run --mode unattended --installdir /opt/intelFPGA/ --accept_eula 1
RUN sed -i -e '$aexport PATH=/opt/intelFPGA/modelsim_ase/bin:$PATH' /home/dockeruser/.bashrc
USER root
RUN rm ModelSimSetup-20.1.1.720-linux.run

FROM vsim-stage AS vnc-stage

# Expose the SSH port
EXPOSE 22
EXPOSE 1
EXPOSE 5901
EXPOSE 6080

USER dockeruser
WORKDIR /home/dockeruser
ENV NOVNC_PATH=/home/dockeruser/noVNC
ENV USER_HOME=/home/dockeruser

RUN $SCRIPTS_DIR/install_noVNC.sh
ENV USER=dockeruser

# RUN vncserver :1 -geometry 1920x1080
# RUN nohup /home/dockeruser/noVNC/utils/novnc_proxy --vnc localhost:5901 --listen 6080 &

USER root
RUN apt-get clean
CMD ["/startup/scripts/entrypoint.sh"]
