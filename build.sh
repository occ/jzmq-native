#!/usr/bin/env bash

set -x

BUILD_OS=`uname -s`
BUILD_ARCH="x86"
if [ `uname -m` != 'x86_64' ]; then
  echo "Need a 64-bit build system"
  exit 1
fi

LIBZMQPREFIX=`pwd`/libzmq_install
JZMQPREFIX=`pwd`/jzmq_install

# Build statically linked libzmq with openpgm
mkdir -p ${LIBZMQPREFIX}/32_bit
mkdir -p ${LIBZMQPREFIX}/64_bit

pushd zeromq3-x
./autogen.sh
CFLAGS=-fPIC CXXFLAGS=-fPIC ./configure --with-pgm --enable-static --disable-shared --prefix=${LIBZMQPREFIX}/64_bit
make
make install

make distclean
./autogen.sh
cat configure.log
CFLAGS="-m32 -fPIC" CXXFLAGS="-m32 -fPIC" ./configure --with-pgm --enable-static --disable-shared --prefix=${LIBZMQPREFIX}/32_bit
make
make install

popd

# Build jzmq

mkdir -p ${JZMQPREFIX}/32_bit
mkdir -p ${JZMQPREFIX}/64_bit

pushd jzmq
./autogen.sh
CFLAGS=-fPIC LIBS=-lrt ./configure --with-zeromq=${LIBZMQPREFIX} --prefix=${JZMQPREFIX}/64_bit
make
make install

make distclean
./autogen.sh
CFLAGS="-m32 -fPIC" LIBS=-lrt ./configure --with-zeromq=${LIBZMQPREFIX} --prefix=${JZMQPREFIX}/32_bit
make
make install
popd

# Build the jar
TEMPJARDIR=$(mktemp -d)

mkdir -p ${TEMPJARDIR}/NATIVE/x86/${BUILD_OS}/
mkdir -p ${TEMPJARDIR}/NATIVE/amd64/${BUILD_OS}/

cp ${JZMQPREFIX}/32_bit/lib/libjzmq.so ${TEMPJARDIR}/NATIVE/x86/${BUILD_OS}/libjzmq.so
cp ${JZMQPREFIX}/64_bit/lib/libjzmq.so ${TEMPJARDIR}/NATIVE/amd64/${BUILD_OS}/libjzmq.so
cp ${JZMQPREFIX}/share/java/zmq.jar .

jar uf zmq.jar -C ${TEMPJARDIR} .
rm -rf ${TEMPJARDIR}
