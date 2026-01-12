#!/usr/bin/env bash

DEFAULT_IMAGE="./CTMRI_patient1_3/0042.png"

IMAGE_PATH="${1:-$DEFAULT_IMAGE}"

octave --no-gui --quiet --eval "RunCanny('${IMAGE_PATH}')"
