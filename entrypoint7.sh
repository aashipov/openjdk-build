#!/bin/sh

set -e

JAVA_VERSION="7"
JDK="jdk"
JRE="jre"
JTREG="jtreg"
JDK_FLAVOR="${JDK}${JAVA_VERSION}u"
JRE_FLAVOR="${JRE}${JAVA_VERSION}u"
JDK_DIR="${HOME}/${JDK_FLAVOR}"
INSTRUCTION_SET="amd64"
GIT_CLONE_URL=https://github.com/openjdk/${JDK_FLAVOR}.git

_SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$0")")
TAG_TO_BUILD=$(cat ${_SCRIPT_DIR}/.tag_to_build_${JAVA_VERSION})
if [ "${TAG_TO_BUILD}" = "" ]
then
    printf "Can not find ${_SCRIPT_DIR}/.tag_to_build_${JAVA_VERSION} file or it is empty\n"
    exit 1
fi

OS_TYPE="linux"
TOP_DIR=${HOME}
JDK_DIR="${TOP_DIR}/${JDK_FLAVOR}"
OS_TYPE_AND_INSTRUCTION_SET="${OS_TYPE}-${INSTRUCTION_SET}"

DEFAULT_BRANCH=master
if [ ! -d "${JDK_DIR}/.git" ]
then
    cd ${TOP_DIR}
    git clone ${GIT_CLONE_URL}
    cd ${JDK_DIR}
else
    cd ${JDK_DIR}
    git checkout ${DEFAULT_BRANCH}
    git pull
fi

RELEASE_IMAGE_DIR=${JDK_DIR}/build/${OS_TYPE_AND_INSTRUCTION_SET}

if [ $(git tag -l "${TAG_TO_BUILD}") ]
then
    git checkout tags/${TAG_TO_BUILD}
else
    printf "Can not find tag ${TAG_TO_BUILD}\n"
    exit 1
fi

MINOR_VER=$(printf ${TAG_TO_BUILD} | cut -d'-' -f 1)
MINOR_VER=${MINOR_VER#${JDK_FLAVOR}}

UPDATE_VER=$(printf ${TAG_TO_BUILD} | cut -d'-' -f 2)
UPDATE_VER=${UPDATE_VER}

MAKE_VARS="JDK_VERSION=1.7.${MINOR_VER} MILESTONE=release BUILD_NUMBER=${UPDATE_VER}"

bash jdk/make/jdk_generic_profile.sh
make clean
make ${MAKE_VARS} sanity
make ${MAKE_VARS}

if [ ${?} -eq 0 ]
then
    cd ${RELEASE_IMAGE_DIR}
    DOT_TAR_DOT_GZ=".tar.gz"
    JDK_FILE_NAME=${JDK_FLAVOR}-${OS_TYPE_AND_INSTRUCTION_SET}-${TAG_TO_BUILD}${DOT_TAR_DOT_GZ}
    JRE_FILE_NAME=${JRE_FLAVOR}-${OS_TYPE_AND_INSTRUCTION_SET}-${TAG_TO_BUILD}${DOT_TAR_DOT_GZ}
    find "${PWD}" -type f -name '*.debuginfo' -exec rm {} \;
    find "${PWD}" -type f -name '*.diz' -exec rm {} \;
    GZIP=-9 tar -czhf ${JDK_FILE_NAME} j2sdk-image/
    GZIP=-9 tar -czhf ${JRE_FILE_NAME} j2re-image/
    
    GITHUB_TOKEN=$(cat ${HOME}/.github_token)
    if [ "${GITHUB_TOKEN}" != "" ]
    then
        GITHUB_OWNER=aashipov
        GITHUB_REPO=openjdk-build
        GITHUB_RELEASE_ID=90555385
        
        FILES_TO_UPLOAD="${JDK_FILE_NAME} ${JRE_FILE_NAME}"
        for file_to_upload in ${FILES_TO_UPLOAD}
        do
            #https://stackoverflow.com/a/7506695
            FILE_NAME_URL_ENCODED=$(printf "${file_to_upload}" | hexdump -v -e '/1 "%02x"' | sed 's/\(..\)/%\1/g')
            curl \
            https://uploads.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/${GITHUB_RELEASE_ID}/assets?name=${FILE_NAME_URL_ENCODED} \
            -H "Authorization: Bearer ${GITHUB_TOKEN}" \
            -H "Content-type: application/gzip" \
            --data-binary @${RELEASE_IMAGE_DIR}/${file_to_upload}
        done
    fi
fi
