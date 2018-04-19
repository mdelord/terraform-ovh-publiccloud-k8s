#!/bin/bash

DIR=${1:-$(dirname $0)/../examples/public-cluster-cl}
REGION=${2:-$OS_REGION_NAME}
DESTROY=${3:-1}
CLEAN=${4:-1}
PROJECT=${OS_TENANT_ID}
VRACK=${OVH_VRACK_ID}
TEST_NAME=${TF_VAR_name:-test}_$(basename "$DIR")
TF_VAR_key_pair=${TF_VAR_key_pair:-test}
TF_VAR_os_region_name=${REGION}
OUTPUT_TEST="tf_test"
WITH_BASTION=0

export TF_VAR_os_region_name

test_tf(){
    # timeout is not 120 seconds but 120 loops, each taking at least 1 sec
    local timeout=120
    local inc=0
    local res=1

    while [ "$res" -ne 0 ] && [ "$inc" -lt "$timeout" ]; do
        (cd "${DIR}" && terraform output ${OUTPUT_TEST} | sh)
        res=$?
        sleep 1
        ((inc++))
    done

    return $res
}

if grep -q bastion_public_ip "$DIR"/*.tf; then
    cp "$(dirname $0)/test_ssh_bastion.tf" "$DIR"
else
    cp "$(dirname $0)/test_ssh_public.tf" "$DIR"
fi

cp "$(dirname $0)/test.tf" "$DIR"

if [ -f "$(dirname $0)/test_counts_$(basename $DIR).tf" ]; then
   cp "$(dirname $0)/test_counts_$(basename $DIR).tf" "$DIR"
else
   cp "$(dirname $0)/test_counts.tf" "$DIR"
fi

sed -i -e s,%%TESTNAME%%,$TEST_NAME,g "$DIR"/test*.tf

# if destroy mode, clean previous terraform setup
if [ "${CLEAN}" == "1" ]; then
    (cd "${DIR}" && rm -Rf .terraform *.tfstate*)
fi

# run the full terraform setup
(cd "${DIR}" && terraform init && terraform apply -auto-approve)
EXIT_APPLY=$?

# if terraform went well run test
if [ "${EXIT_APPLY}" == 0 ]; then
    test_tf
    EXIT_APPLY=$?
fi

# if destroy mode, clean terraform setup
if [ "${DESTROY}" == "1" ]; then
    (cd "${DIR}" && terraform destroy -auto-approve && rm -Rf .terraform *.tfstate* test*.tf)
    EXIT_DESTROY=$?
else
    EXIT_DESTROY=0
fi

exit $((EXIT_APPLY+EXIT_DESTROY))
