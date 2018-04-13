#!/bin/bash

REGIONS=${1:-$OS_REGION_NAME}
#DIRS=(public-cluster-cl private-cluster-cl public-cluster-with-workers-cl)
DIRS=(public-cluster-with-workers-cl)

if [ ! -f "$SSH_AUTH_SOCK" ]; then
    eval $(ssh-agent) && ssh-add ${TEST_SSH_PRIVATE_KEY:-$HOME/.ssh/id_rsa}
fi

for d in ${DIRS[@]}; do
    for r in $REGIONS; do
        if ! $(dirname $0)/runtest.sh "$(dirname $0)/../examples/$d" "$r"; then
            echo "last test failed. skipping nexts."
            exit 1
        fi
    done
done
