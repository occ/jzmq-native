#!/usr/bin/env bash

set -x

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

mkdir -p ${TEMPJARDIR}/NATIVE/amd64/Linux
cp ${JZMQPREFIX}/lib/libjzmq.so ${TEMPJARDIR}/NATIVE/amd64/Linux/libjzmq.so
cp ${JZMQPREFIX}/share/java/zmq.jar .

jar uf zmq.jar -C ${TEMPJARDIR} .
rm -rf ${TEMPJARDIR}
