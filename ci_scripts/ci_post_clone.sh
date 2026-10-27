#!/bin/sh

set -e

defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES

cd "${CI_PRIMARY_REPOSITORY_PATH:-$(dirname "$0")/..}"

curl https://mise.jdx.dev/install.sh | sh
"$HOME/.local/bin/mise" install
"$HOME/.local/bin/mise" exec -- tuist generate --no-open
