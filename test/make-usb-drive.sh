#!/usr/bin/env bash

set -xeu
set -o pipefail

device=$1

printf "y\ny\n" |
  make-encrypted-usb-drive -t \
    -i /etc/issue \
    -k /etc/issue \
    "$device"

# Ensure all the correct devices were created:
for n in 1 2 3 4; do
  test -b "$device$n"
done

mkdir -p /mnt
mount "$device"1 /mnt
test -e /mnt/issue
