#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
# shellcheck source=../lib/encryption-utils.sh
. "$(dirname "$0")/../lib/encryption-utils.sh"

################################################################################
option_years=2
option_key_id=

################################################################################
function usage() {
  cat <<EOF
Usage: $(basename "$0") [options] email-address-or-key-id

  -h      This message
  -y N    Extend the key for N years [default: $option_years]

EOF
}

################################################################################
function gpg_edit_key() {
  options=(
    "--command-fd=0"
    "--status-fd=1"
  )

  gpg_ "${options[@]}" --edit-key "$option_key_id" "$@"
}

################################################################################
function main() {
  while getopts "hTy:" o; do
    case "${o}" in
    h)
      usage
      exit
      ;;

    T)
      set -x
      option_interactive=0
      gpg_options+=(
        "--pinentry-mode" "loopback"
        "--passphrase" ""
      )
      ;;

    y)
      option_years=$OPTARG
      ;;

    *)
      exit 1
      ;;
    esac
  done

  shift $((OPTIND - 1))

  gpg_ensure_state

  if [ "$#" -ne 1 ]; then
    echo >&2 "ERROR: missing key-id/email-address"
    exit 1
  fi

  option_key_id=$1

  human_date=$(date --date="$option_years years" +%s)
  human_date=$((human_date - 86400)) # Expires one day short
  human_date=$(date --date="@$human_date" "+%A, %x")

  prompt \
    "Extending key expiration date to $human_date" \
    "You'll need to unlock the primary key."

  printf "y\n%dy\n" "$option_years" |
    gpg_edit_key "key *" "expire" "save"

  gpg_backup_keys "$option_key_id"
}

################################################################################
main "$@"
