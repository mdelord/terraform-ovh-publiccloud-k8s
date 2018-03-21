#!/bin/bash -uxe

VERSION=2.7.14.2717
PACKAGE=ActivePython-${VERSION}-linux-x86_64-glibc-2.12-404899

# make directory
mkdir -p /opt/bin
cd /opt

# get sources
wget http://downloads.activestate.com/ActivePython/releases/${VERSION}/${PACKAGE}.tar.gz
tar -xzvf ${PACKAGE}.tar.gz

# install
mv ${PACKAGE} apy && cd apy && ./install.sh -I /opt/python/

# add binaries to path
mkdir /etc/bash/bashrc.d
cat << EOF > /etc/bash/bashrc.d/python
export PATH="$PATH:/opt/python/bin"
EOF
