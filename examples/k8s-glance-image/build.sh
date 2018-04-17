#!/bin/bash
PACKERBIN=$(which packer-io || which packer)
TARGET="${1:-coreos}"
VERSION=${2:-$((git describe --tags || git rev-parse --verify --short HEAD) 2>/dev/null)}
COMMIT=$(git rev-parse --verify --short HEAD 2>/dev/null)

$PACKERBIN build \
           -var region="$OS_REGION_NAME" \
           -var ext_net_id=$(openstack network show -c id -f value "Ext-Net") \
           -var version="$VERSION" \
           -var commit="$COMMIT" \
           -only "$TARGET" \
           packer.json

