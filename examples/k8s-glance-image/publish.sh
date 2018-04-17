#!/bin/bash

# PGP Signing ID
PGP_SIGN_ID=B3EA8AB9

# Pgp key passphrase file
PGP_KEY_PASSPHRASE_FILE=$(dirname $0)/../../.gpg.passphrase

# The openstack region where to create the swift container
CONTAINER_REGION=${CONTAINER_REGION:-$OS_REGION_NAME}

# The name of the swift container
CONTAINER_NAME=${CONTAINER_NAME:-"ovhcommunity"}

# The name of the swift container
IMAGES_PREFIX=${IMAGES_PREFIX:-"images"}

# Image where the region has been built
IMAGE_REGION=${IMAGE_REGION:-$OS_REGION_NAME}

# Image name
IMAGE_NAME=${1:-"CoreOS Stable K8s"}

# Image version
IMAGE_VERSION=${2:-"latest"}

# Swift container segment size (1024*1024*128 = 128M)
SEGMENT_SIZE=134217728

# computing image file name
image_file_name="$(echo "${IMAGE_NAME}_${IMAGE_VERSION}.raw" | tr ' ' '_' | tr '[:upper:]'  '[:lower:]')"

# Retrieving most recent image id
echo "getting id for image with name '$IMAGE_NAME' and version '$IMAGE_VERSION' in region '$IMAGE_REGION'" >&2
image_id=$(openstack --os-region-name "$IMAGE_REGION" image list \
                     --name "$IMAGE_NAME" \
                     --property "version=$IMAGE_VERSION" \
                     --sort "created_at:desc" \
                     --status active \
                     -f value \
                     -c ID | head -1)

if [ -z "${image_id}" ]; then
    echo "Unable to find image" >&2
    exit 1
fi

# Retrieving image checksum
echo "getting checksum for image with id '$image_id'" >&2
image_checksum=$(openstack --os-region-name "$IMAGE_REGION" image show \
                           -f value \
                           -c checksum \
                           "$image_id")


# creating tmp dir
tmp_dir=$(mktemp -d)
echo "downloading image in '$tmp_dir'" >&2

# download raw image
if ! openstack --os-region-name "$IMAGE_REGION" image save --file "${tmp_dir}/${image_file_name}" "${image_id}"; then
    echo "Unable to downlong image '${image_id}' in '${tmp_dir}'" >&2
    exit 1
fi

# compute downloaded file checksum
echo "computing downloaded image checksum" >&2
(cd ${tmp_dir} && md5sum ${image_file_name} > ${image_file_name}.md5sum.txt)

# check checksum
file_checksum="$(awk '{print $1}' ${tmp_dir}/${image_file_name}.md5sum.txt)"
if [ "${file_checksum}" != "${image_checksum}" ]; then
    echo "Image checksum '$image_checksum' is not equal to downloaded file checksum '${file_checksum}'" >&2
    exit 1
fi

# sign files
echo "signing image file in '$tmp_dir'" >&2
gpg --batch --passphrase-file "$PGP_KEY_PASSPHRASE_FILE" -u "$PGP_SIGN_ID" --detach-sig ${tmp_dir}/${image_file_name}
echo "signing image checksum fil in '$tmp_dir'" >&2
gpg --batch --passphrase-file "$PGP_KEY_PASSPHRASE_FILE" -u "$PGP_SIGN_ID" --detach-sig ${tmp_dir}/${image_file_name}.md5sum.txt

# create swift container
echo "creating swift container '$CONTAINER_NAME' in region '${CONTAINER_REGION}'" >&2
openstack --os-region-name "$CONTAINER_REGION" container create "${CONTAINER_NAME}" >/dev/null
# make it publicly readable
swift --os-region-name "$CONTAINER_REGION" post --read-acl ".r:*" "${CONTAINER_NAME}" >/dev/null

# upload files on container
echo "uploading files from '$tmp_dir' in swift container '$CONTAINER_NAME'" >&2
swift --os-region-name "$CONTAINER_REGION" upload -S "$SEGMENT_SIZE" \
      --object-name "$IMAGES_PREFIX" "$CONTAINER_NAME" \
      "${tmp_dir}"
