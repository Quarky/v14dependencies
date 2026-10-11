#!/bin/bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$DIR/export_modules.py"
printf '\nPress Return to close.\n'
read -r _
