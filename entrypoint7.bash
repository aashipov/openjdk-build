#!/bin/bash

set -ex

JAVA_VERSION="7"
JDK="jdk"
JRE="jre"
JTREG="jtreg"
JDK_FLAVOR="${JDK}${JAVA_VERSION}u"
JRE_FLAVOR="${JRE}${JAVA_VERSION}u"
JDK_DIR="${HOME}/${JDK_FLAVOR}"
INSTRUCTION_SET="amd64"
OS_TYPE_AND_INSTRUCTION_SET="linux-${INSTRUCTION_SET}"

if [ ! -d "${JDK_DIR}/.git" ] 
then
   cd ${HOME}
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
UPDATE_VER=${UPDATE_VER}

MAKE_VARS="JDK_VERSION=1.7.${MINOR_VER} MILESTONE=release BUILD_NUMBER=${UPDATE_VER}"

bash jdk/make/jdk_generic_profile.sh
make clean
make ${MAKE_VARS} sanity
make ${MAKE_VARS}

if [[ $? -eq 0 ]]
then
  cd ${JDK_DIR}/build/${OS_TYPE_AND_INSTRUCTION_SET}/
  printf $(git rev-parse --verify HEAD) > j2sdk-image/release
  printf "\n" >> j2sdk-image/release
  printf ${TOP_TAG} >> j2sdk-image/release
  printf $(git rev-parse --verify HEAD) > j2re-image/release
  printf "\n" >> j2re-image/release
  printf ${TOP_TAG} >> j2re-image/release
  find "${PWD}" -type f -name '*.debuginfo' -exec rm {} \;
  find "${PWD}" -type f -name '*.diz' -exec rm {} \;
  GZIP=-9 tar -czhf ./${JDK_FLAVOR}-${OS_TYPE_AND_INSTRUCTION_SET}-${TOP_TAG}.tar.gz j2sdk-image/
  GZIP=-9 tar -czhf ./${JRE_FLAVOR}-${OS_TYPE_AND_INSTRUCTION_SET}-${TOP_TAG}.tar.gz j2re-image/
fi
