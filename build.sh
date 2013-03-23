#!/usr/bin/env bash

LIBZMQPREFIX=`pwd`/libzmq_install
mkdir -p ${LIBZMQPREFIX}
pushd zeromq3-x
./autogen.sh
CFLAGS=-fPIC CXXFLAGS=-fPIC ./configure --with-pgm --enable-static --disable-shared --prefix=$LIBZMQPREFIX
make
make install
popd


