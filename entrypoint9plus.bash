#!/bin/bash

set -ex

JAVA_VERSION=${1}
JDK="jdk"
JRE="jre"
JTREG="jtreg"
GTEST="googletest"
JDK_FLAVOR="${JDK}${JAVA_VERSION}u"
JRE_FLAVOR="${JRE}${JAVA_VERSION}u"
INSTRUCTION_SET="x86_64"

OS_TYPE="linux"
TOP_DIR=${HOME}
# https://github.com/archlinux/svntogit-packages/blob/packages/java11-openjdk/trunk/PKGBUILD
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
GTEST_DIR="${TOP_DIR}/${GTEST}"
OS_TYPE_AND_INSTRUCTION_SET="${OS_TYPE}-${INSTRUCTION_SET}"

ALPINE=""
if [ -f /etc/alpine-release ]; then
    ALPINE="-alpine"
fi

if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ]; then
    source /opt/rh/devtoolset-7/enable
fi

# if [[ "${JAVA_VERSION}" = "11" ]]; then
#     if [ ! -d "${JTREG_DIR}/.git" ]; then
#         cd ${TOP_DIR}
#         git clone https://github.com/openjdk/${JTREG}.git
#         cd ${JTREG_DIR}
#     else
#         cd ${JTREG_DIR}
#         git pull
#     fi
#     bash make/build.sh --jdk ${JAVA_HOME}
# fi
# if [[ "${JAVA_VERSION}" = "17" ]]; then
#     if [ ! -d "${GTEST_DIR}/.git" ]; then
#         cd ${TOP_DIR}
#         git clone https://github.com/google/googletest
#         cd ${GTEST_DIR}
#     else
#         cd ${GTEST_DIR}
#         git checkout master
#     fi
#     git checkout tags/release-1.8.1
# fi

if [ ! -d "${JDK_DIR}/.git" ]; then
    cd ${TOP_DIR}
    git clone https://github.com/openjdk/${JDK_FLAVOR}.git
    cd ${JDK_DIR}
else
    cd ${JDK_DIR}
    git checkout master
    git pull
fi

# https://gist.github.com/rponte/fdc0724dd984088606b0 or commit sha
TOP_TAG=$(git describe --tags $(git rev-list --tags --max-count=1))
git checkout ${TOP_TAG}

export CFLAGS=${_CFLAGS}
export CXXFLAGS=${_CFLAGS}

bash configure \
    --verbose \
    --with-debug-level=release \
    --with-native-debug-symbols=none \
    --with-jvm-variants=server \
    --with-freetype=bundled \
    --with-version-pre="" \
    --with-version-opt="" \
    --with-extra-cflags="${_CFLAGS}" \
    --with-extra-cxxflags="${_CFLAGS}" \
    --enable-unlimited-crypto \
    --disable-warnings-as-errors \
    --with-version-string="${TOP_TAG#${JDK}-}"
#--with-memory-size=4096 \
#--with-num-cores=2 \
#--with-toolchain-type=clang \
#--with-jtreg=${JTREG_DIR}/build/images/jtreg \
#--with-gtest=${GTEST_DIR}

make clean
STARTTIME=$(date +%s)
make images legacy-jre-image docs
ENDTIME=$(date +%s)
echo "Compilation took $((${ENDTIME} - ${STARTTIME})) seconds"

if [[ $? -eq 0 ]]; then
    if [[ "${JAVA_VERSION}" == "11" ]]; then
        cd ${JDK_DIR}/build/${OS_TYPE_AND_INSTRUCTION_SET}-normal-server-release/images/
    elif [[ "${JAVA_VERSION}" == "17" ]]; then
        cd ${JDK_DIR}/build/${OS_TYPE_AND_INSTRUCTION_SET}-server-release/images/
    fi
    find "${PWD}" -type f -name '*.debuginfo' -exec rm {} \;
    find "${PWD}" -type f -name '*.diz' -exec rm {} \;
    GZIP=-9 tar -czhf ./${JDK_FLAVOR}-${OS_TYPE_AND_INSTRUCTION_SET}-${TOP_TAG}${ALPINE}.tar.gz jdk/
    GZIP=-9 tar -czhf ./${JRE_FLAVOR}-${OS_TYPE_AND_INSTRUCTION_SET}-${TOP_TAG}${ALPINE}.tar.gz jre/
fi

#cd ${JDK_DIR}
#make run-test-tier1
