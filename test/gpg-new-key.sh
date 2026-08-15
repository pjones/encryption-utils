#!/usr/bin/env bash

set -eux
set -o pipefail

test -n "${GNUPGHOME:-}"
public="$(dirname "$(dirname "$GNUPGHOME")")/public"

# Should set up GNUPGHOME:
gpg-prepare -T /dev/vdb

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

# Remove the subkeys and ensure we can restore from backup:
test "$(gpg --list-secret-keys foo@example.com | grep -cE '^ssb ')" -eq 3

while read -r key; do
  gpg \
    --batch --yes \
    --delete-secret-keys "${key}!"
done < <(
  gpg --list-secret-keys --with-colons foo@example.com |
    grep -E '^fpr' | tail -3 | cut -d: -f10
)

test "$(gpg --list-secret-keys foo@example.com | grep -cE '^ssb ')" -eq 0
gpg --import "$GNUPGHOME/../backup/$(date +%Y-%m-%d)-subkeys.txt"
test "$(gpg --list-secret-keys foo@example.com | grep -cE '^ssb ')" -eq 3

################################################################################
# Test the expiration extension script.
function test_ensure_expries_in() {
  local opt=$1
  local years=$2
  local subkeys=0

  # NOTE: We subtract 24 hours (86400 seconds) because GPG will expire
  # the key one day short of the set time.  We also take away another
  # 30 seconds to prevent race conditions.
  years_from_now=$(date --date="$years years" +%s)
  years_from_now=$((years_from_now - 86400 - 30))

  while read -r expires; do
    test "$expires" "$opt" "$years_from_now"
    subkeys=$((subkeys + 1))
  done < <(
    gpg --list-keys --with-colons "foo@example.com" |
      grep -E "^sub:" |
      cut -d: -f7
  )

  test "$subkeys" -eq 3
}

# Now extend the expiration date by 5 years ():
test_ensure_expries_in -lt 3
gpg-extend-key.sh -T -y 5 "foo@example.com"
test_ensure_expries_in -ge 5
