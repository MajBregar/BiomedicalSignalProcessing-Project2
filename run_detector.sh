#!/usr/bin/env bash

DEFAULT_IMAGE="./CTMRI/patient1/3/0034.png"

IMAGE_PATH="${1:-$DEFAULT_IMAGE}"

octave --no-gui --quiet --eval "RunCanny('${IMAGE_PATH}')"
