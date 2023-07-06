#!/bin/env bash

# This stupid script is needed because gpg2 doesn't work without a
# running agent, and the default agent can't find the pinentry
# program.

set -eu
set -o pipefail

@gpgAgent@ --pinentry-program @pinentry@ "$@"
