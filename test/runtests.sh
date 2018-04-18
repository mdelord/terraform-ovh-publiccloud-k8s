#!/bin/bash

REGIONS=${1:-$OS_REGION_NAME}
PUBLISH=$2
BASEDIR="$(dirname $0)/.."

DIRS=(public-cluster-cl public-cluster-cl-prebuilt private-cluster-cl public-cluster-with-workers-cl)

# build packer image
(cd examples/k8s-glance-image && make coreos)

if [ ! -f "$SSH_AUTH_SOCK" ]; then
    eval $(ssh-agent) && ssh-add ${TEST_SSH_PRIVATE_KEY:-$HOME/.ssh/id_rsa}
fi

for d in ${DIRS[@]}; do
    for r in $REGIONS; do
        if ! "$BASEDIR/test/runtest.sh" "$BASEDIR/examples/$d" "$r"; then
            echo "last test failed. skipping nexts."
            exit 1
        fi
    done
done

if [ "$PUBLISH" == "publish" ]; then
    # if everything is ok, publish
    (cd "$BASEDIR/examples/k8s-glance-image" && make publish-coreos)
fi
