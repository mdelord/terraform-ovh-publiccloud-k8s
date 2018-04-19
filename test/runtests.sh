#!/bin/bash

REGIONS=${1:-$OS_REGION_NAME}
PUBLISH=$2
BASEDIR="$(dirname $0)/.."
TF_VAR_name=${TF_VAR_name:-test}
TESTS=${TESTS:-public-cluster-cl public-cluster-cl-prebuilt private-cluster-cl public-cluster-with-workers-cl}
TEST_SSH_PRIVATE_KEY=${TEST_SSH_PRIVATE_KEY}

## begin ssh setup
if [ -z "$TEST_SSH_PRIVATE_KEY" ]; then
    TEST_SSH_PRIVATE_KEY=$(mktemp -u)
    echo "generating keypair for test purposes" >&2
    ssh-keygen -f "$TEST_SSH_PRIVATE_KEY" -t rsa -N ''
fi

if [ ! -f "$SSH_AUTH_SOCK" ]; then
    eval $(ssh-agent)
fi

if ! ssh-add "${TEST_SSH_PRIVATE_KEY}"; then
    echo "couldn't add ssh private key $TEST_SSH_PRIVATE_KEY to agent. aborting" >&2
    exit 1
fi

echo "creating openstack keypair according to test ssh key $TEST_SSH_PRIVATE_KEY" >&2
if ! openstack keypair create --public-key "$TEST_SSH_PRIVATE_KEY.pub" "$TF_VAR_name"; then
    echo "couldn't create test keypair. aborting" >&2
    exit 1
fi

export TF_VAR_key_pair="$TF_VAR_name"
export TF_VAR_public_sshkey="$TEST_SSH_PRIVATE_KEY.pub"
## end ssh setup

# build packer image
if ! (cd examples/k8s-glance-image && make coreos); then
    echo "Image build failed. aborting" >&2
    exit 1
fi

for t in ${TESTS[@]}; do
    for r in $REGIONS; do
        echo "running test $t on region $r." >&2
        if ! "$BASEDIR/test/runtest.sh" "$BASEDIR/examples/$t" "$r"; then
            echo "test $t on region $r failed. skipping nexts." >&2
            exit 1
        fi
    done
done

if [ "$PUBLISH" == "publish" ]; then
    # if everything is ok, publish
    (cd "$BASEDIR/examples/k8s-glance-image" && make publish-coreos)
fi
