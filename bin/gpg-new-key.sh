#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
option_algo_new="ed25519/cert,sign+cv25519/encr"
option_algo_sub="future-default"
option_years=2
option_email=()

################################################################################
# shellcheck source=../lib/encryption-utils.sh
. "$(dirname "$0")/../lib/encryption-utils.sh"

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

  prompt "Creating primary key.  Choose a passphrase for the key."

  gpg_ \
    --default-new-key-algo "$option_algo_new" \
    --quick-generate-key "$primary_email" default cert never

  fp=$(
    # shellcheck disable=SC2012
    ls -t "$GNUPGHOME/openpgp-revocs.d" |
      head -1
  )

  if [ "${#option_email[@]}" -gt 0 ]; then
    for email in "${option_email[@]}"; do
      prompt \
        "Adding secondary address: $email." \
        "You'll need to unlock the primary key."

      gpg_ --quick-add-uid "$primary_email" "$email"
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
    prompt \
      "Creating subkey \"$usage\"." \
      "You'll need to unlock the primary key."

    gpg_ \
      --quick-add-key \
      "$fingerprint" \
      "$option_algo_sub" \
      "$usage" \
      "$expire"
  done
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
      option_interactive=0
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

  gpg_ensure_state

  if [ "${#option_email[@]}" -eq 0 ]; then
    echo >&2 "ERROR: you must use -e at least once"
    exit 1
  fi

  fingerprint=$(make_primary_key)
  make_sub_keys "$fingerprint"
  gpg_backup_keys "$fingerprint"

  cat >&2 <<DONE
==> Done!

Your new key's fingerprint is $fingerprint.

Now you need to upload your keys to a smartcard using:

    gpg --edit-key $fingerprint

Select keys with the 'key <number>' command and upload a key with the
'keytocard' command.

DONE
}

################################################################################
main "$@"
