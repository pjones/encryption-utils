#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
# shellcheck source=../lib/encryption-utils.sh
. "$(dirname "$0")/../lib/encryption-utils.sh"

################################################################################
option_disk_device=/dev/sda2
option_mount_point=/mnt/keys
option_key_id=204284CB
option_pub_key=/pub/public.txt

################################################################################
usage() {
  cat <<EOF
Usage: $(basename "$0") -k ID [options]
Mount an encrypted drive then extend subkey expiration dates.

Options:
  -k ID    The secret key ID to extend
  -d DEV   Decrypt device DEV [$option_disk_device]
  -m DIR   Mount the device on DIR [$option_mount_point]
EOF
}

################################################################################
parse_command_line() {
  while getopts "hd:k:" o; do
    case "${o}" in
    d)
      option_disk_device=$OPTARG
      ;;

    k)
      option_key_id=$OPTARG
      ;;

    h)
      usage
      exit
      ;;

    *)
      exit 1
      ;;
    esac
  done

  shift $((OPTIND - 1))

  if [ -z "$option_key_id" ]; then
    echo >&2 "ERROR: you must provide a key ID"
    exit 1
  fi

  if [ ! -e "$option_disk_device" ]; then
    echo >&2 "ERROR: drive does not exist: $option_disk_device"
    exit 1
  fi
}

################################################################################
backup() {
  if [ -z "$GNUPGHOME" ]; then
    echo >&2 "ERROR: Whoa, GNUPGHOME isn't set!"
    exit 1
  fi

  sudo_ mkdir -p "$GNUPGHOME/../backup"

  sudo_ tar -C "$GNUPGHOME/.." -czf \
    "$GNUPGHOME/../backup/$(date +%Y-%m-%d-%s).tar.gz" \
    "$(basename $GNUPGHOME)"
}

################################################################################
main() {
  local username
  local crypt_name
  local self
  local agent
  local pub_name

  parse_command_line "$@"

  username=$(whoami)
  crypt_name=$(make_crypt_device_name "$option_mount_point")

  self="$(realpath "$0")"
  agent=$(realpath "$(dirname "$self")/..")/libexec/gpg-agent-wrapper.sh

  export GNUPGHOME=$option_mount_point/gnupg
  pub_name=$GNUPGHOME/../backup/$(date +%Y-%m-%d)-public.txt

  echo "=> Decrypting and mounting $option_disk_device"
  cryptsetup_ open "$option_disk_device" "$crypt_name"

  echo "=> Mounting decrypted device to $option_mount_point"
  sudo_ mkdir -p "$option_mount_point"
  sudo_ mount "/dev/mapper/$crypt_name" "$option_mount_point"
  sudo_ chown -R "$username" "$option_mount_point"

  echo "=> Dropping into GPG to edit key, type 'save' when done"
  do_cmd gpg2 --agent-program="$agent" --edit-key "$option_key_id"

  echo "=> Backup up keys"
  backup

  echo "=> Exporting public key to $option_pub_key"
  do_cmd gpg2 \
    --agent-program="$agent" \
    --armor \
    --export "$option_key_id" \
    >"$pub_name"

  sudo_ mkdir -p "$(dirname "$option_pub_key")"
  sudo_ cp "$pub_name" "$option_pub_key"

  echo "=> Unmounting device $option_disk_device"
  sudo_ umount "$option_mount_point"
  cryptsetup_ close "$crypt_name"

  echo "=> Done"
}

################################################################################
main "$@"
