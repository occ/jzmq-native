#!/usr/bin/env bash

BUILD_OS=`uname -s`
if [ "${BUILD_ARCH}" == "" ]; then
  BUILD_ARCH=`uname -m`
fi

LIBZMQPREFIX=`pwd`/libzmq_install
JZMQPREFIX=`pwd`/jzmq_install
JAVA_OS_ARCH=${BUILD_ARCH}

export CFLAGS="-fPIC"
export CXXFLAGS="-fPIC"
export LIBS="-lrt"

if [ "${BUILD_ARCH}" == "x86" ]; then
  export CFLAGS="${CFLAGS} -m32"
  export CXXFLAGS="${CXXFLAGS} -m32"
elif [ "${BUILD_ARCH}" == "x86_64" ]; then
  JAVA_OS_ARCH="amd64"
fi


# Build statically linked libzmq with openpgm
mkdir -p ${LIBZMQPREFIX}

pushd zeromq3-x
./autogen.sh
./configure --with-pgm --enable-static --disable-shared --prefix=${LIBZMQPREFIX}
make
make install
popd

# Build jzmq
mkdir -p ${JZMQPREFIX}

pushd jzmq
./autogen.sh
./configure --with-zeromq=${LIBZMQPREFIX} --prefix=${JZMQPREFIX}
make
make install
popd

# Build the jar
TEMPJARDIR=$(mktemp -d)

mkdir -p ${TEMPJARDIR}/NATIVE/${JAVA_OS_ARCH}/${BUILD_OS}/
cp ${JZMQPREFIX}/lib/libjzmq.so ${TEMPJARDIR}/NATIVE/${JAVA_OS_ARCH}/${BUILD_OS}/libjzmq.so
cp ${JZMQPREFIX}/share/java/zmq.jar .

jar uf zmq.jar -C ${TEMPJARDIR} .

# Push the artifacts when running on Travis
if [ "${TRAVIS}" == "true" ]; then
  KEYFILE=$(mktemp)
  BASE64_DECODE_PARAM="-d"
  if [ "${BUILD_OS}" == "Darwin" ]; then
    BASE64_DECODE_PARAM="-D"
  fi
  echo $DEPLOY_KEY_{1..27} | sed 's/ //g' | base64 ${BASE64_DECODE_PARAM} | gzip --decompress > $KEYFILE
  SSH_AGENT_SETUP=$(mktemp)  
  ssh-agent > $SSH_AGENT_SETUP
  source $SSH_AGENT_SETUP
  rm $SSH_AGENT_SETUP
  ssh-add $KEYFILE

  TEMPARTIFACTREPO=$(mktemp -d)
  pushd ${TEMPARTIFACTREPO}
  git init
  git remote add origin git@github.com:occ/jzmq-native-artifacts.git
  git config --local user.email "travis@occ.me"
  git config --local user.name "Travis CI"
  git pull origin master
  cp -rf ${TEMPJARDIR}/* .
  git add .
  git commit -m "Artifacts from Travis. ${TRAVIS_REPO_SLUG}@${TRAVIS_COMMIT}"
  git push origin master:master
  popd

  kill -9 ${SSH_AGENT_PID}
fi

# Clean up
rm -rf ${TEMPJARDIR}
rm -rf ${TEMPARTIFACTREPO}
rm -rf ${KEYFILE}
