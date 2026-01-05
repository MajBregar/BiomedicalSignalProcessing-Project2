#!/usr/bin/env bash

DEFAULT_IMAGE="./CTMRI/patient1/2/0001.png"

IMAGE_PATH="${1:-$DEFAULT_IMAGE}"

octave --no-gui --quiet --eval "RunCanny('${IMAGE_PATH}')"
