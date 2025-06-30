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

COPY ./ModelSimSetup-20.1.1.720-linux.run .
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
ENV NOVNC_PATH = /home/dockeruser/noVNC
ENV USER_HOME = /home/dockeruser

RUN $SCRIPTS_DIR/install_noVNC.sh
ENV USER=dockeruser

# RUN vncserver :1 -geometry 1920x1080
# RUN nohup /home/dockeruser/noVNC/utils/novnc_proxy --vnc localhost:5901 --listen 6080 &

USER root
RUN apt-get clean
CMD ["/startup/scripts/entrypoint.sh"]
# RUN git clone https://github.com/novnc/noVNC
# COPY scripts/xstart /home/dockeruser/.vnc/xstartup
# RUN chown dockeruser:dockeruser -R .vnc/
# RUN chown dockeruser:dockeruser -R noVNC/

# RUN chmod +x /home/dockeruser/.vnc/xstartup
# RUN printf "pippopippo\npippopippo\n\n" | vncserver :1

# RUN ./noVNC/utils/novnc_proxy --vnc localhost:5901 --listen 6080 &

# Run the SSH server

# FROM ubuntu:20.04 AS ubuntu-stage

# # LABEL about the custom image
# LABEL maintainer="Francesco Mignone - IlNerdChuck"
# LABEL version="0.1"
# LABEL description="This is a custom Docker Image to gather hardware developing tools."
# # Sets the timezone
# ENV TZ=EU
# # Disables the prompts for some packet installation
# ARG DEBIAN_FRONTEND=noninteractive
# ENV USER=ubuntu \
#     PASSWORD=ubuntu \
#     UID=1000 \
#     GID=1000
# ENV REMOTE_DESKTOP=nomachine
# ENV VNC_THREADS=2

# WORKDIR /startup
# # setup scripts
# COPY scripts /startup/scripts
# RUN chmod +x /startup/scripts/*.sh
# ENV SCRIPTS_DIR=/startup/scripts

# RUN apt-get update && apt-get install -y \
#     wget \
#     git \
#     python3 \
#     openssh-server openssl \
#     python3-pip && apt-get clean

# RUN bash $SCRIPTS_DIR/pre_install.sh

# FROM ubuntu-stage AS modelsim-stage

# # RUN yum install -y libiodbc unixODBC ncurses ncurses-libs \
# #     zeromq-devel libXext alsa-lib libXtst libXft libxml2 libedit libX11 libXi \
# #     glibc glibc.i686 glibc-devel.i386 libgcc.i686 libstdc++-devel.i686 libstdc++ \
# #     libstdc++.i686 libXext libXext.i686 libXft libXft.i686 libXrender libXtst

# # For now ditch questasim

# # WORKDIR /tmp
# # # RUN yum install python2
# # # RUN sudo python2 mgclicgen.py
# # # ENV QUESTA_VERSION=22.2
# # # ENV QUESTA_VERSION_FULL=22.2.0.94
# # # RUN curl -sS -O https://downloads.intel.com/akdlm/software/acdsinst/22.2/94/ib_installers/QuestaSetup-22.2.0.94-linux.run
# # # RUN curl -sS -O https://downloads.intel.com/akdlm/software/acdsinst/22.2/94/ib_installers/questa_part2-22.2.0.94-linux.qdz
# # COPY ./ModelSimSetup-20.1.1.720-linux.run .
# # RUN chmod +x ModelSimSetup-20.1.1.720-linux.run
# # RUN ./ModelSimSetup-20.1.1.720-linux.run --mode unattended --installdir /opt/intelFPGA/ --accept_eula 1
# # RUN rm ModelSimSetup-20.1.1.720-linux.run
# # ENV PATH="/opt/intelFPGA/modelsim_ase/bin:${PATH}"

# FROM modelsim-stage AS vnc-stage
# WORKDIR /startup

# # Update the package list and install a gui environment
# RUN apt-get update && apt-get install -y \
#     xfce4 \
#     xfce4-terminal && apt-get clean

# ENV DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket
# RUN mkdir -p /var/run/dbus

# # Set environment variables and ports
# ENV DISPLAY=:1 \
#     VNC_PORT=5901 \
#     NO_VNC_PORT=6080 \
#     VNC_COL_DEPTH=24 \
#     VNC_RESOLUTION=1280x1024 \
#     VNC_PW=vncpassword \
#     VNC_VIEW_ONLY=false
# EXPOSE $VNC_PORT $NO_VNC_PORT

# RUN bash $SCRIPTS_DIR/post_install.sh

# RUN mkdir -p /var/run/sshd
# RUN sed -i 's/#*PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
# RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

# EXPOSE 22 4000

# CMD ["sh","/startup/scripts/entrypoint.sh"]
# # FROM centos:centos7 AS base

# # LABEL \
# #     org.opencontainers.image.title="Hardware Verification CI Docker container" \
# #     org.opencontainers.image.description="Modelsim for HW Development." \
# #     org.opencontainers.image.authors="Francesco Mignone <fmignone98@gmail.com>"
# # # org.opencontainers.image.source="https://github.com/ilnerdchuck/hw-tools-docker"

# # # Set the working directory inside the container
# # WORKDIR /work

# # RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/CentOS-*.repo
# # RUN sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/CentOS-*.repo
# # RUN sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/CentOS-*.repo

# # RUN yum -y update
# # RUN yum clean all

# # RUN curl -o /tmp/endpoint-rpmsign-7.pub https://packages.endpointdev.com/endpoint-rpmsign-7.pub
# # RUN rpm --import /tmp/endpoint-rpmsign-7.pub
# # RUN rpm -qi gpg-pubkey-703df089 | gpg --with-fingerprint
# # RUN rm /tmp/endpoint-rpmsign-7.pub
# # RUN yum install -y https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm
# # RUN yum update -y
# # RUN yum install -y git make epel-release

# # # Update the package manager and install any necessary tools
# # # RUN yum -y install \
# # #     vim \
# # #     git \
# # #     wget && yum clean all

# # FROM base AS python3
# # ENV PYTHON_VER=3.9.13
# # RUN yum groupinstall "Development Tools" -y
# # RUN yum -y install python3

# RUN pip3 install --upgrade pip setuptools
# RUN pip3 install wheel

# # VNC Server for GUI applications
# FROM modelsim AS vnc
# ## Connection ports for controlling the UI:
# # VNC port:5901
# # noVNC webport, connect via http://IP:6901/?password=vncpassword
# ENV DISPLAY=:1 \
#     VNC_PORT=5901 \
#     NO_VNC_PORT=6080
# EXPOSE $VNC_PORT $NO_VNC_PORT

# ### Envrionment config
# ENV HOME=/headless \
#     TERM=xterm \
#     STARTUPDIR=/dockerstartup \
#     INST_SCRIPTS=/headless/install \
#     NO_VNC_HOME=/headless/noVNC \
#     VNC_COL_DEPTH=24 \
#     VNC_RESOLUTION=1280x1024 \
#     VNC_PW=vncpassword \
#     VNC_VIEW_ONLY=false
# WORKDIR $HOME

# RUN echo "Install TigerVNC server"
# RUN yum install -y tigervnc-server wget
# # RUN yum --enablerepo=epel -y install novnc python-websockify numpy openssl
# RUN yum --enablerepo=epel -y install numpy openssl firewalld
# RUN yum groupinstall "Xfce" -y
# RUN yum clean all
# RUN git clone https://github.com/novnc/noVNC.git /headless/noVNC
# # RUN systemctl isolate graphical.target

# # RUN openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/pki/tls/certs/novnc.pem -out /etc/pki/tls/certs/novnc.pem -days 365 -batch
# # RUN mkdir /headless/vnc/
# # # Set a VNC password
# # RUN echo "useruseruser" | vncpasswd -f >/headless/vnc/passwd
# # RUN chmod 600 /headless/vnc/passwd
# # RUN printf "password\npassword\n\n" | vncpasswd
# # RUN vncserver :1 -geometry 800x600 -depth 24
# # # Start VNC session
# # RUN websockify -D --web=/usr/share/novnc/ --cert=/etc/pki/tls/certs/novnc.pem 6080 localhost:5901

# #RUN echo '\n# docker-headless-vnc-container:\nlocalhost=no\n' >>/etc/tigervnc/vncserver-config-defaults
# #RUN set -e
# #RUN set -u
# #
# #RUN echo "Install noVNC - HTML5 based VNC viewer"
# #RUN mkdir -p $NO_VNC_HOME/utils/websockify
# #RUN wget -qO- https://github.com/novnc/noVNC/archive/refs/tags/v1.3.0.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME
# # use older version of websockify to prevent hanging connections on offline containers, see https://github.com/ConSol/docker-headless-vnc-container/issues/50
# # RUN wget -qO- https://github.com/novnc/websockify/archive/refs/tags/v0.10.0.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME/utils/websockify
# #chmod +x -v $NO_VNC_HOME/utils/*.sh
# # create index.html to forward automatically to `vnc_lite.html`
# # RUN ln -s $NO_VNC_HOME/vnc_lite.html $NO_VNC_HOME/index.html
# # Use ghdl for now
# # RUN yum install ghdl
# # FROM questasim AS verilator
# # RUN yum -y install verilator
# # Set the default command to run when the container starts
# FROM vnc AS final
# # CMD ["/bin/bash"]
