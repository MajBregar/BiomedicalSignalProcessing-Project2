#!/usr/bin/env bash

DEFAULT_IMAGE_FOLDER="./CTMRI/patient1/3"
OUTPUT_FOLDER="./canny3D_outputs"

FOLDER_PATH="${1:-$DEFAULT_IMAGE_FOLDER}"

mapfile -t IMAGES < <(ls "$FOLDER_PATH"/*.{png,jpg,jpeg,tif,tiff} 2>/dev/null | sort -V)

if [ ${#IMAGES[@]} -eq 0 ]; then
    echo "No images found in $FOLDER_PATH"
    exit 1
fi

IMAGE_LIST=$(printf "'%s'," "${IMAGES[@]}")
IMAGE_LIST="{${IMAGE_LIST%,}}"


octave --no-gui --quiet --eval "RunCanny3D($IMAGE_LIST, '$OUTPUT_FOLDER');"
