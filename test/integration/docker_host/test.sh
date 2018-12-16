#!/bin/sh

TEMP_DIR=$(mktemp -d)
TEST_DIR="$(cd "$(dirname "${0}")"; echo "$(pwd)")"

ALIASES=$(cd "${TEST_DIR}/../../..//dist"; echo "$(pwd)/aliases -c ${TEST_DIR}/aliases.yaml")
DIFF=$(if which colordiff >/dev/null; then echo "colordiff -Buw --strip-trailing-cr"; else echo "diff -Buw --strip-trailing-cr"; fi)
MASK="sed -e s|${HOME}|[HOME]|g -e s|${TEMP_DIR}|[TEMP_DIR]|g"

if ! docker inspect some-docker >/dev/null 2>&1; then
    docker run -it --privileged --publish 2375:2375 --name some-docker -d docker:dind >/dev/null
fi
PORT=$(docker inspect --format='{{range $p, $conf :=.NetworkSettings.Ports}}{{ $p }}{{ end }}' some-docker | grep -o "[0-9]*")
export DOCKER_HOST="tcp://localhost:${PORT}"

set -eu

${DIFF} ${TEST_DIR}/alias   - <<<"$(${ALIASES} gen --export-path "${TEMP_DIR}" | ${MASK} | sort)"
${DIFF} ${TEST_DIR}/export  - <<<"$(${ALIASES} gen --export --export-path "${TEMP_DIR}" | ${MASK})"
${DIFF} ${TEST_DIR}/stdout  - <<<"$(${TEMP_DIR}/alpine /bin/sh -c "/usr/local/bin/kubectl version --client" | ${MASK})"

docker stop some-docker >/dev/null
docker rm some-docker >/dev/null