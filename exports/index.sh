#!/bin/sh
printf '\033c\033]0;%s\a' 2_smoking_barrels
base_path="$(dirname "$(realpath "$0")")"
"$base_path/index.arm64" "$@"
