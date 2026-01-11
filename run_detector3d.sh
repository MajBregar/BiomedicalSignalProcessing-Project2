#!/usr/bin/env bash

DEFAULT_IMAGE_FOLDER="./CTMRI/patient1/3"
CANNY_2D_OUTPUTS="./canny2D_outputs"
CANNY_3D_OUTPUTS="./canny3D_outputs"

FOLDER_PATH="${1:-$DEFAULT_IMAGE_FOLDER}"

mapfile -t IMAGES < <(ls "$FOLDER_PATH"/*.{png,jpg,jpeg,tif,tiff} 2>/dev/null | sort -V)

if [ ${#IMAGES[@]} -eq 0 ]; then
    echo "No images found in $FOLDER_PATH"
    exit 1
fi

IMAGE_LIST=$(printf "'%s'," "${IMAGES[@]}")
IMAGE_LIST="{${IMAGE_LIST%,}}"


octave --eval "RunCanny3D($IMAGE_LIST, '$CANNY_2D_OUTPUTS', '$CANNY_3D_OUTPUTS');"

python generate_comparison_pdf.py $FOLDER_PATH $CANNY_2D_OUTPUTS $CANNY_3D_OUTPUTS canny3d_output_comparisons.pdf 4