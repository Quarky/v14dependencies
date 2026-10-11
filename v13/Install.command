#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
"$DIR/install.sh" "$@"
STATUS=$?
printf '\nFoundry V13 dependency installer finished with status %s.\nPress Return to close.\n' "$STATUS"
read -r _
exit "$STATUS"
