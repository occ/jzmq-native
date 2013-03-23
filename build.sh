#!/usr/bin/env bash

set -x

BUILD_OS=`uname -s`
BUILD_ARCH="x86"
if [ `uname -m` == 'x64_64' ]; then
  BUILD_ARCH="amd64"
fi

LIBZMQPREFIX=`pwd`/libzmq_install
JZMQPREFIX=`pwd`/jzmq_install

# Build statically linked libzmq with openpgm
mkdir -p ${LIBZMQPREFIX}
pushd zeromq3-x
./autogen.sh
CFLAGS=-fPIC CXXFLAGS=-fPIC ./configure --with-pgm --enable-static --disable-shared --prefix=$LIBZMQPREFIX
make
make install
popd

# Build jzmq
mkdir -p ${JZMQPREFIX}
pushd jzmq
./autogen.sh
CFLAGS=-fPIC LIBS=-lrt ./configure --with-zeromq=${LIBZMQPREFIX} --prefix=${JZMQPREFIX}
make
make install
popd

# Build the jar
TEMPJARDIR=$(mktemp -d)
JZMQNATIVEDIR="${TEMPJARDIR}/NATIVE/${BUILD_ARCH}/${BUILD_OS}"

mkdir -p ${JZMQNATIVEDIR}
cp ${JZMQPREFIX}/lib/libjzmq.so ${JZMQNATIVEDIR}/libjzmq.so
cp ${JZMQPREFIX}/share/java/zmq.jar .

jar uf zmq.jar -C ${TEMPJARDIR} .
rm -rf ${TEMPJARDIR}
