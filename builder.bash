#!/bin/bash

# Build vanilla openJDK upstream from source

function usage {
    echo "usage: $(basename $0) distro java_version"
    echo "  distro  - opensuse or debian"
    echo "  version - java version to build (8, 11 or 17)"
    exit 1
}

if [ $# -ne 2 ]; then
    usage
fi

set -x

DISTRO=${1}
JAVA_VERSION=${2}
JDK="jdk"
JDK_AND_JAVA_VERSION=${JDK}${JAVA_VERSION}u
JTREG="jtreg"
GTEST="googletest"
JDK_BUILDER="${JDK}builder"
DOCKER_HUB_USER_AND_REPOSITORY="aashipov/openjdk-build"

TAG="${DISTRO}${JDK_BUILDER}"
IMAGE="${DOCKER_HUB_USER_AND_REPOSITORY}:${TAG}"

docker stop ${TAG}
docker rm ${TAG}
docker pull ${IMAGE}
if [[ $? -ne 0 ]]
then 
    docker build --file=Dockerfile.${DISTRO}.${JDK_BUILDER} --tag ${IMAGE} .
    docker push ${IMAGE}
fi

DUMMY_USER="dummy"
THIS_DIR="$(pwd)"
if [[ "${JAVA_VERSION}" = "11" ]] || [[ "${JAVA_VERSION}" = "17" ]]; then
    ENTRYPOINT_FILENAME="entrypoint9plus.bash"
    CMD="bash /${DUMMY_USER}/${ENTRYPOINT_FILENAME} ${JAVA_VERSION}"
else
    ENTRYPOINT_FILENAME="entrypoint${JAVA_VERSION}.bash"
    CMD="bash /${DUMMY_USER}/${ENTRYPOINT_FILENAME}"
fi
VOLUMES="-v ${HOME}/${JDK_AND_JAVA_VERSION}/:/${DUMMY_USER}/${JDK_AND_JAVA_VERSION} -v ${HOME}/${JTREG}/:/${DUMMY_USER}/${JTREG} -v ${HOME}/${GTEST}/:/${DUMMY_USER}/${GTEST} -v ${THIS_DIR}/${ENTRYPOINT_FILENAME}:/${DUMMY_USER}/${ENTRYPOINT_FILENAME}"

TAG="${DISTRO}${JDK_AND_JAVA_VERSION}"
IMAGE="${DOCKER_HUB_USER_AND_REPOSITORY}:${TAG}"

docker stop ${TAG}
docker rm ${TAG}
docker pull ${IMAGE}
if [[ $? -ne 0 ]]
then 
    docker build --file=Dockerfile.${DISTRO}.${JAVA_VERSION} --tag ${IMAGE} .
    docker push ${IMAGE}
fi

mkdir -p ${HOME}/${JDK_AND_JAVA_VERSION} ${HOME}/${JTREG} ${HOME}/${GTEST}

docker run -it --name=${TAG} --hostname=${TAG} --user=${DUMMY_USER} --workdir=/${DUMMY_USER}/ ${VOLUMES} ${IMAGE} ${CMD}
