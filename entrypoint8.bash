#!/bin/bash

set -ex

JAVA_VERSION="8"
JDK="jdk"
JRE="jre"
JTREG="jtreg"
JDK_FLAVOR="${JDK}${JAVA_VERSION}u"
JRE_FLAVOR="${JRE}${JAVA_VERSION}u"
INSTRUCTION_SET="x86_64"

OS_TYPE="linux"
TOP_DIR=${HOME}
# https://raw.githubusercontent.com/archlinux/svntogit-packages/packages/java8-openjdk/trunk/PKGBUILD
# Avoid optimization of HotSpot being lowered from O3 to O2
_CFLAGS="-O3"
if [[ "${OSTYPE}" == "cygwin" || "${OSTYPE}" == "msys" ]]; then
  OS_TYPE="windows"
  TOP_DIR="/cygdrive/c"
  export JAVA_HOME=${TOP_DIR}/dev/tools/openjdk${JAVA_VERSION}
  _CFLAGS="/O2"
fi
JDK_DIR="${TOP_DIR}/${JDK_FLAVOR}"
JTREG_DIR="${TOP_DIR}/${JTREG}"
OS_TYPE_AND_INSTRUCTION_SET="${OS_TYPE}-${INSTRUCTION_SET}"

ALPINE=""
if [ -f /etc/alpine-release ] ; then
  ALPINE="-alpine"
fi

if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ] ; then
    source /opt/rh/devtoolset-7/enable
fi

if [ ! -d "${JDK_DIR}/.git" ]
then
    cd ${TOP_DIR}
    git clone https://github.com/openjdk/${JDK_FLAVOR}.git
    cd ${JDK_DIR}
else
    cd ${JDK_DIR}
    git checkout master
    git pull
fi

# https://gist.github.com/rponte/fdc0724dd984088606b0 or commit sha
TOP_TAG=$(git describe --tags `git rev-list --tags --max-count=1`)
git checkout ${TOP_TAG}

MINOR_VER=$(printf ${TOP_TAG} | cut -d'-' -f 1)
MINOR_VER=${MINOR_VER#${JDK_FLAVOR}}

UPDATE_VER=$(printf ${TOP_TAG} | cut -d'-' -f 2)
UPDATE_VER=${UPDATE_VER#"b"}

export CFLAGS=${_CFLAGS}
export CXXFLAGS=${_CFLAGS}

bash configure \
--verbose \
--with-debug-level=release \
--with-native-debug-symbols=none \
--with-jvm-variants=server \
--with-milestone="fcs" \
--enable-unlimited-crypto \
--with-extra-cflags="${_CFLAGS}" \
--with-extra-cxxflags="${_CFLAGS}" \
--enable-jfr=yes \
--with-update-version="${MINOR_VER}" \
--with-build-number="${UPDATE_VER}" \
#--with-freetype-src=${TOP_DIR}/dev/VCS/freetype-2.5.3

make clean
make all

if [[ $? -eq 0 ]]
then
  cd ${JDK_DIR}/build/${OS_TYPE_AND_INSTRUCTION_SET}-normal-server-release/images/
  printf $(git rev-parse --verify HEAD) > j2sdk-image/release
  printf "\n" >> j2sdk-image/release
  printf ${TOP_TAG} >> j2sdk-image/release
  printf $(git rev-parse --verify HEAD) > j2re-image/release
  printf "\n" >> j2re-image/release
  printf ${TOP_TAG} >> j2re-image/release
  find "${PWD}" -type f -name '*.debuginfo' -exec rm {} \;
  find "${PWD}" -type f -name '*.diz' -exec rm {} \;
  GZIP=-9 tar -czhf ./${JDK_FLAVOR}-${OS_TYPE_AND_INSTRUCTION_SET}-${TOP_TAG}${ALPINE}.tar.gz j2sdk-image/
  GZIP=-9 tar -czhf ./${JRE_FLAVOR}-${OS_TYPE_AND_INSTRUCTION_SET}-${TOP_TAG}${ALPINE}.tar.gz j2re-image/
fi
