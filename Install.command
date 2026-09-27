#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
"$DIR/install.sh" "$@"
STATUS=$?
echo
if [ $STATUS -eq 0 ]; then
  echo "Foundry V14 dependency installer finished."
else
  echo "Installer failed with status $STATUS."
fi
echo "Press Return to close."
read -r _
exit $STATUS
