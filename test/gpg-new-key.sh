#!/usr/bin/env bash

set -eux
set -o pipefail

# Get disks ready for gpg-prepare:
make-encrypted-dev -s 128 -k /etc/issue -! /dev/vdb

export GNUPGHOME=/mnt/keys/gnupg
public="$(dirname "$(dirname "$GNUPGHOME")")/public"

# Should set up GNUPGHOME:
gpg-prepare \
  -k /etc/issue \
  -p 1 -g 2 \
  /dev/vdb

test -d "$GNUPGHOME"
test -d "$public"

gpg-new-key.sh -t \
  -e 'Joe T. Foo <foo@example.com>' \
  -e bar@example.com

# Will fail if key doesn't exist:
gpg --list-keys foo@example.com

num=$(
  gpg --list-secret-keys foo@example.com |
    grep -cE '(ed|cv)25519'
)

test "$num" -eq 4
test -d "$GNUPGHOME/../backup"
test "$(find "$GNUPGHOME/../backup" -type f | wc -l)" -eq 3
test -s "$GNUPGHOME/../backup/$(date +%Y-%m-%d)-subkeys.txt"
test -e "$public/public.txt"
