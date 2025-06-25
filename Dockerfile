# -----------------------------------------------------------------------------
# Dockerfile for HE Developing
# Author: Francesco Mignone - IlNerdChuck
# Created: 24-06-2025
# Description: A Docker containing most of the tools needed to develop HDL
#              languages for simulation and synthesis
# -----------------------------------------------------------------------------
# Use the official CentOS image as the base image
FROM centos:centos7 AS base

LABEL \
    org.opencontainers.image.title="Hardware Verification CI Docker container" \
    org.opencontainers.image.description="Modelsim for HW Development." \
    org.opencontainers.image.authors="Francesco Mignone <fmignone98@gmail.com>"
# org.opencontainers.image.source="https://github.com/Mluckydwyer/hw-ci"

# Set the working directory inside the container
WORKDIR /work

RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/CentOS-*.repo
RUN sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/CentOS-*.repo
RUN sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/CentOS-*.repo

RUN yum -y update
RUN yum clean all

# RUN curl -o /tmp/endpoint-rpmsign-7.pub https://packages.endpointdev.com/endpoint-rpmsign-7.pub && \
#     rpm --import /tmp/endpoint-rpmsign-7.pub && \
#     rpm -qi gpg-pubkey-703df089 | gpg --with-fingerprint && \
#     rm /tmp/endpoint-rpmsign-7.pub && \
#     yum install -y https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm && \
#     yum update -y && \
#     yum install -y git make epel-release

# Update the package manager and install any necessary tools
# RUN yum -y install \
#     vim \
#     git \
#     wget && yum clean all

FROM base AS python3
ENV PYTHON_VER=3.9.13
RUN yum groupinstall "Development Tools" -y
RUN yum -y install python3

RUN pip3 install --upgrade pip setuptools
RUN pip3 install wheel

FROM python3 AS questasim
RUN yum install -y libiodbc unixODBC ncurses ncurses-libs \
    zeromq-devel libXext alsa-lib libXtst libXft libxml2 libedit libX11 libXi \
    glibc glibc.i686 glibc-devel.i386 libgcc.i686 libstdc++-devel.i686 libstdc++ \
    libstdc++.i686 libXext libXext.i686 libXft libXft.i686 libXrender libXtst
WORKDIR /tmp
ENV QUESTA_VERSION=22.2
ENV QUESTA_VERSION_FULL=22.2.0.94
RUN curl -sS -O https://downloads.intel.com/akdlm/software/acdsinst/22.2/94/ib_installers/QuestaSetup-22.2.0.94-linux.run
RUN curl -sS -O https://downloads.intel.com/akdlm/software/acdsinst/22.2/94/ib_installers/questa_part2-22.2.0.94-linux.qdz
RUN chmod +x QuestaSetup-${QUESTA_VERSION_FULL}-linux.run
RUN ./QuestaSetup-${QUESTA_VERSION_FULL}-linux.run --mode unattended --installdir /opt/intelFPGA/${QUESTA_VERSION} --accept_eula 1 --questa_edition questa_fse
RUN rm QuestaSetup-${QUESTA_VERSION_FULL}-linux.run
ENV PATH="/opt/intelFPGA/${QUESTA_VERSION}/questa_fse/bin:${PATH}"

FROM questasim AS verilator
RUN yum -y install verilator
# Set the default command to run when the container starts
# CMD ["/bin/bash"]
