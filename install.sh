#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULE_ID="northern-fjord-curated-maps-v14"
MODULE_SOURCE="$SCRIPT_DIR/$MODULE_ID"

DEFAULT_ROOT="$HOME/Library/Application Support/FoundryVTTV14"
FOUNDRY_ROOT="\${FOUNDRY_V14_ROOT:-$DEFAULT_ROOT}"
MODULES_DIR="$FOUNDRY_ROOT/Data/modules"
UPDATE=0

for arg in "$@"; do
  case "$arg" in
    --update) UPDATE=1 ;;
    --help|-h)
      cat <<'EOF'
Skyhorn / Foundry V14 dependency installer

Usage:
  ./install.sh
  ./install.sh --update

Environment:
  FOUNDRY_V14_ROOT
    Override the default Foundry v14 root.

Default:
  ~/Library/Application Support/FoundryVTTV14

This installer:
- installs the additive curated-map helper module from this checkout;
- installs public-manifest map-source modules when configured;
- reports Foundry-exclusive / Marketplace sources that need normal Foundry/provider installation;
- never removes unrelated modules.
EOF
      exit 0
      ;;
  esac
done

say() { printf '%s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

command -v curl >/dev/null 2>&1 || fail "curl is required."
command -v unzip >/dev/null 2>&1 || fail "unzip is required."

mkdir -p "$MODULES_DIR"
TMP_ROOT="$(mktemp -d "\${TMPDIR:-/tmp}/v14dependencies.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

json_field() {
  local file="$1"
  local field="$2"
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$file" "$field" <<'PY'
import json, sys
p, field = sys.argv[1], sys.argv[2]
with open(p, encoding="utf-8") as f:
    data = json.load(f)
value = data
for part in field.split("."):
    if not isinstance(value, dict) or part not in value:
        print("")
        raise SystemExit(0)
    value = value[part]
print(value if value is not None else "")
PY
  elif command -v plutil >/dev/null 2>&1; then
    plutil -extract "$field" raw -o - "$file" 2>/dev/null || true
  else
    fail "Need python3 or plutil to read module manifests."
  fi
}

install_local_curator() {
  [ -f "$MODULE_SOURCE/module.json" ] || fail "Missing $MODULE_SOURCE/module.json"
  [ -f "$MODULE_SOURCE/scripts/curated-maps.js" ] || fail "Missing curated-map script."

  local stage="$TMP_ROOT/$MODULE_ID"
  rm -rf "$stage"
  cp -R "$MODULE_SOURCE" "$stage"

  local target="$MODULES_DIR/$MODULE_ID"
  if [ -e "$target" ]; then
    say "Replacing existing $MODULE_ID ..."
    rm -rf "$target"
  else
    say "Installing $MODULE_ID ..."
  fi

  mv "$stage" "$target"

  [ -f "$target/module.json" ] || fail "Curated-map module install verification failed."
  [ -f "$target/scripts/curated-maps.js" ] || fail "Curated-map script verification failed."
  say "  installed: $target"
}

install_manifest_module() {
  local expected_id="$1"
  local label="$2"
  local manifest_url="$3"
  local target="$MODULES_DIR/$expected_id"

  if [ -d "$target" ] && [ "$UPDATE" -ne 1 ]; then
    say "Already installed: $label ($expected_id)"
    return 0
  fi

  local work="$TMP_ROOT/\${expected_id}-download"
  mkdir -p "$work"
  local manifest="$work/module.json"

  say "Fetching manifest: $label"
  if ! curl -fL --retry 2 --connect-timeout 15 "$manifest_url" -o "$manifest"; then
    warn "Could not retrieve $label manifest. Skipping."
    return 0
  fi

  local actual_id download
  actual_id="$(json_field "$manifest" "id")"
  download="$(json_field "$manifest" "download")"

  if [ -z "$actual_id" ]; then
    warn "$label manifest did not contain an id. Skipping."
    return 0
  fi
  if [ "$actual_id" != "$expected_id" ]; then
    warn "$label manifest id was '$actual_id', expected '$expected_id'. Skipping for safety."
    return 0
  fi
  if [ -z "$download" ]; then
    warn "$label manifest has no direct download URL. Install it through Foundry Setup/provider UI."
    return 0
  fi

  local zip="$work/module.zip"
  if ! curl -fL --retry 2 --connect-timeout 15 "$download" -o "$zip"; then
    warn "Could not download $label. Skipping."
    return 0
  fi

  local extracted="$work/extracted"
  mkdir -p "$extracted"
  unzip -q "$zip" -d "$extracted"

  local source=""
  if [ -f "$extracted/module.json" ]; then
    source="$extracted"
  elif [ -f "$extracted/$expected_id/module.json" ]; then
    source="$extracted/$expected_id"
  else
    local found
    found="$(find "$extracted" -maxdepth 3 -type f -name module.json -print -quit)"
    if [ -n "$found" ]; then
      source="$(dirname "$found")"
    fi
  fi

  if [ -z "$source" ] || [ ! -f "$source/module.json" ]; then
    warn "$label download did not contain a recognizable module root. Skipping."
    return 0
  fi

  local staged="$TMP_ROOT/\${expected_id}-stage"
  rm -rf "$staged"
  mv "$source" "$staged"

  if [ -e "$target" ]; then
    say "Updating $label ..."
    rm -rf "$target"
  else
    say "Installing $label ..."
  fi
  mv "$staged" "$target"

  [ -f "$target/module.json" ] || fail "$label installation did not verify."
  say "  installed: $target"
}

report_manual_source() {
  local id="$1"
  local label="$2"
  local url="$3"
  if [ -d "$MODULES_DIR/$id" ]; then
    say "Available source: $label ($id)"
  else
    say "Manual source not installed: $label"
    say "  Foundry/provider page: $url"
  fi
}

say "Foundry V14 dependency installer"
say "Foundry root: $FOUNDRY_ROOT"
say "Modules:      $MODULES_DIR"
say

install_local_curator

say
say "Public-manifest map sources"
install_manifest_module "czepeku" "CZEPEKU Universe" "https://www.czepeku.com/fvtt-module.json"

say
say "Foundry-exclusive / Marketplace / provider-managed map sources"
report_manual_source "miskasmaps" "Miska's Maps - Battlemap Pack" "https://foundryvtt.com/packages/miskasmaps"
report_manual_source "moonlight-maps-free" "Moonlight Maps" "https://foundryvtt.com/packages/moonlight-maps-free"
report_manual_source "tomcartos-into-the-wilds-maps" "Tom Cartos - Into the Wilds Maps" "https://foundryvtt.com/packages/tomcartos-into-the-wilds-maps"
report_manual_source "tomcartos-ostenwold" "Tom Cartos Ostenwold" "https://foundryvtt.com/packages/tomcartos-ostenwold"
report_manual_source "mad-taverns" "The MAD Cartographer - Taverns" "https://foundryvtt.com/packages/mad-taverns"

say
say "Done."
say "Enable 'Skyhorn — Curated Additive Maps' in the v14 world, then run:"
say "  Skyhorn Maps — Preview Curated Sources"
say "  Skyhorn Maps — Import Curated Additions"
say
say "Use './install.sh --update' later to refresh auto-installable dependencies."
