#!/usr/bin/env bash

################################################################################
option_key_file=
option_pass_name=
tmp_keyfile=

################################################################################
# Ensure any temporary files are cleaned up.
cleanup() {
  if [ -n "$tmp_keyfile" ] && [ -e "$tmp_keyfile" ]; then
    rm "$tmp_keyfile"
  fi
}
trap cleanup EXIT

################################################################################
# Read password on standard output if requested.
prepare_password() {
  if [ -n "$option_key_file" ]; then
    if [ "$option_key_file" = "-" ]; then
      tmp_keyfile=$(mktemp --tmpdir=/dev/shm keyfile.XXXXXXXXXX)
      cat >"$tmp_keyfile"
      option_key_file=$tmp_keyfile
    fi
  fi
}

################################################################################
# Write the image password to standard output.
password_to_stdout() {
  if [ -n "$option_key_file" ]; then
    cat "$option_key_file"
  elif [ -n "$option_pass_name" ]; then
    pass show "$option_pass_name" | head -1
  fi
}

################################################################################
do_cmd() {
  echo >&2 "$@"
  "$@"
}

################################################################################
# Run a command using sudo if necessary.
sudo_() {
  if [ "$(id -u)" -ne 0 ]; then
    do_cmd sudo "$@"
  else
    do_cmd "$@"
  fi
}

################################################################################
# Run cryptsetup with proper flags for the key file.
cryptsetup_() {
  local flags=("--batch-mode")

  if [ -n "$option_key_file" ] || [ -n "$option_pass_name" ]; then
    flags+=("--key-file" "-")
    password_to_stdout |
      sudo_ cryptsetup "${flags[@]}" "$@"
  else
    flags+=("-y")
    sudo_ cryptsetup "${flags[@]}" "$@"
  fi
}

################################################################################
# Generate a cryptsetup device name from another device name.
make_crypt_device_name() {
  local device=$1

  basename "$device" |
    sed -E \
      -e 's/[^a-zA-Z0-9_-]+/_/g' \
      -e 's/$/_crypt/'
}

################################################################################
join_array_with() {
  local delimiter=$1
  shift

  local first_element=$1
  shift

  printf "%s" "$first_element" "${@/#/$delimiter}"
}
