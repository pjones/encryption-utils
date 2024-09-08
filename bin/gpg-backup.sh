#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
main() {
  local home=${GNUPGHOME:=$HOME/.gnupg}

  mkdir -p "$home/../backup"

  tar \
    --directory "$home/.." \
    --create \
    --gzip \
    --file "$home/../backup/$(date +%Y-%m-%d).tar.gz" \
    "$(basename "$home")"
}

################################################################################
main "$@"
