#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
option_algo="ed25519/cert,sign+cv25519/encr"
option_years=2
option_email=()

################################################################################
gpg_options=("--batch" "--yes")

################################################################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [options] -e email-address

  -e ADDR Add an email address to the new key
  -E N    Expire keys in N years (default: $option_years)
  -h      This message
  -t      Enable settings for testing this script

  The -e option can be repeated multiple times.

EOF
}

################################################################################
make_primary_key() {
  local primary_email="${option_email[0]}"
  local fp

  # Remove the primary email address from the list.
  unset 'option_email[0]'

  gpg \
    "${gpg_options[@]}" \
    --default-new-key-algo "$option_algo" \
    --quick-generate-key "$primary_email" default cert never

  fp=$(
    # shellcheck disable=SC2012
    ls -t "$GNUPGHOME/openpgp-revocs.d" |
      head -1
  )

  if [ "${#option_email[@]}" -gt 0 ]; then
    for email in "${option_email[@]}"; do
      gpg --quick-add-uid "$primary_email" "$email"
    done
  fi

  # Return the key's fingerprint.
  basename "$fp" .rev
}

################################################################################
make_sub_keys() {
  local fingerprint=$1
  local usages=("sign" "encr" "auth")

  local expire
  expire=$(date --date="$option_years years" +%Y-%m-%d)

  for usage in "${usages[@]}"; do
    gpg \
      "${gpg_options[@]}" \
      --quick-add-key \
      "$fingerprint" \
      "$option_algo" \
      "$usage" \
      "$expire"
  done
}

################################################################################
backup_keys() {
  local fingerprint=$1

  local today
  today=$(date +%Y-%m-%d)

  full=$(realpath "$(dirname "$0")/gpg-backup.sh")
  "$full"

  gpg \
    --armor \
    --output "$GNUPGHOME/../backup/$today-public.txt" \
    --export "$fingerprint"

  gpg \
    --armor \
    --export-secret-subkeys "$fingerprint" \
    >"$GNUPGHOME/../backup/$today-subkeys.txt"
}

################################################################################
main() {
  local fingerprint

  # Option arguments are in $OPTARG
  while getopts "e:E:ht" o; do
    case "${o}" in
    e)
      option_email+=("$OPTARG")
      ;;

    E)
      option_years=$OPTARG
      ;;

    h)
      usage
      exit
      ;;

    t)
      set -x
      gpg_options+=(
        "--pinentry-mode" "loopback"
        "--passphrase" ""
      )
      ;;

    *)
      exit 1
      ;;
    esac
  done

  shift $((OPTIND - 1))

  if [ -n "${GNUPGHOME:-}" ]; then
    mkdir -p "$GNUPGHOME"
  else
    echo >&2 "ERROR: please set GNUPGHOME first"
    exit 1
  fi

  if [ "${#option_email[@]}" -eq 0 ]; then
    echo >&2 "ERROR: you must use -e at least once"
    exit 1
  fi

  fingerprint=$(make_primary_key)
  make_sub_keys "$fingerprint"
  backup_keys "$fingerprint"

  cat <<DONE
==> Done!

Your new key's fingerprint is $fingerprint.
DONE
}

################################################################################
main "$@"
