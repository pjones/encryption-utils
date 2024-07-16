#!/usr/bin/env bash

################################################################################
option_key_file=
option_pass_name=
tmp_keyfile=

################################################################################
# Ensure any temporary files are cleaned up.
lib_cleanup() {
  if [ -n "$tmp_keyfile" ] && [ -e "$tmp_keyfile" ]; then
    rm "$tmp_keyfile"
  fi
}
trap lib_cleanup EXIT

################################################################################
# Call one of the scripts passing in the current authentication options.
call_internal_script() {
  local script=$1
  shift

  local auth_options=()

  if [ -n "$option_key_file" ]; then
    auth_options+=("-k" "$option_key_file")
  fi

  if [ -n "$option_pass_name" ]; then
    auth_options+=("-p" "$option_pass_name")
  fi

  "$script" "${auth_options[@]}" "$@"
}

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
    pass show "$option_pass_name" |
      head -1 |
      tr -d '\n'
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
    if [ "$1" = "luksFormat" ]; then
      flags+=("-y")
    fi

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

################################################################################
# Calculate the size of the given directory, in bytes.
calc_directory_size() {
  local directory=$1

  du --bytes --summarize "$directory" |
    cut -f1
}
