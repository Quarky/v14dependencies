#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REGISTRY="$SCRIPT_DIR/dependencies-v14.json"
DEFAULT_ROOT="$HOME/Library/Application Support/FoundryVTTV14"
FOUNDRY_ROOT="\${FOUNDRY_V14_ROOT:-$DEFAULT_ROOT}"
MODULES_DIR="$FOUNDRY_ROOT/Data/modules"
UPDATE=0

for arg in "$@"; do
  case "$arg" in
    --update) UPDATE=1 ;;
    --help|-h)
      cat <<'EOF'
Foundry V14 dependency installer

Usage:
  ./install.sh
  ./install.sh --update

Environment:
  FOUNDRY_V14_ROOT
    Override the default:
    ~/Library/Application Support/FoundryVTTV14

Scope:
  Automatic dependency installation only.
  Campaign modules and curated map packs are installed separately.
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
command -v python3 >/dev/null 2>&1 || fail "python3 is required."
[ -f "$REGISTRY" ] || fail "Missing dependency registry: $REGISTRY"

mkdir -p "$MODULES_DIR"
TMP_ROOT="$(mktemp -d "\${TMPDIR:-/tmp}/v14dependencies.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

json_field() {
  local file="$1"
  local field="$2"
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
  if ! curl -fL --retry 2 --connect-timeout 20 "$manifest_url" -o "$manifest"; then
    warn "Could not retrieve manifest for $label. Skipping."
    return 0
  fi

  local actual_id download
  actual_id="$(json_field "$manifest" "id")"
  download="$(json_field "$manifest" "download")"

  if [ "$actual_id" != "$expected_id" ]; then
    warn "$label manifest id was '$actual_id', expected '$expected_id'. Skipping for safety."
    return 0
  fi

  if [ -z "$download" ]; then
    warn "$label manifest has no direct download URL. Skipping."
    return 0
  fi

  local zip="$work/module.zip"
  if ! curl -fL --retry 2 --connect-timeout 20 "$download" -o "$zip"; then
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
    found="$(find "$extracted" -type f -name module.json -print | head -n 1)"
    if [ -n "$found" ]; then source="$(dirname "$found")"; fi
  fi

  if [ -z "$source" ] || [ ! -f "$source/module.json" ]; then
    warn "$label archive did not contain a recognizable module root. Skipping."
    return 0
  fi

  local installed_id
  installed_id="$(json_field "$source/module.json" "id")"
  if [ "$installed_id" != "$expected_id" ]; then
    warn "$label archive module id was '$installed_id', expected '$expected_id'. Skipping."
    return 0
  fi

  local stage="$TMP_ROOT/\${expected_id}-stage"
  rm -rf "$stage"
  mv "$source" "$stage"

  if [ -e "$target" ]; then
    say "Updating $label ..."
    rm -rf "$target"
  else
    say "Installing $label ..."
  fi
  mv "$stage" "$target"

  [ -f "$target/module.json" ] || fail "$label installation verification failed."
  say "  installed: $target"
}

LIST_FILE="$TMP_ROOT/dependencies.tsv"
python3 - "$REGISTRY" > "$LIST_FILE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data=json.load(f)
for pkg in data.get("packages", []):
    if pkg.get("installMode") != "manifest":
        continue
    print("\t".join([
        str(pkg.get("id","")),
        str(pkg.get("name","")),
        str(pkg.get("manifest",""))
    ]))
PY

say "Foundry V14 dependency installer"
say "Foundry root: $FOUNDRY_ROOT"
say "Modules:      $MODULES_DIR"
say

COUNT=0
while IFS="$(printf '\t')" read -r id name manifest; do
  [ -n "$id" ] || continue
  [ -n "$manifest" ] || continue
  COUNT=$((COUNT + 1))
  install_manifest_module "$id" "$name" "$manifest"
done < "$LIST_FILE"

if [ "$COUNT" -eq 0 ]; then
  say "No auto-installable dependencies are currently registered."
fi

say
say "Dependency installation complete."
say "No campaign modules were installed or modified."
