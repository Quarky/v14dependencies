#!/usr/bin/env python3
"""Safely install pinned Foundry v13 dependencies. Python standard library only."""
import argparse, datetime, json, os, shutil, stat, sys, tempfile, urllib.request, zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
DEFAULT_ROOT = Path.home() / "Library" / "Application Support" / "FoundryVTT"

def fail(msg):
    raise RuntimeError(msg)

def remote(url, label, destination=None):
    if not url.startswith("https://"):
        fail(label + ": refused non-HTTPS source")
    req = urllib.request.Request(url, headers={"User-Agent": "Foundry-V13-Dependencies/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=90) as response:
            if destination:
                with destination.open("wb") as out:
                    shutil.copyfileobj(response, out)
                return None
            return json.load(response)
    except Exception as exc:
        fail(label + ": download error: " + str(exc))

def major(v):
    try:
        return int(str(v).split(".")[0])
    except (TypeError, ValueError):
        return None

def validate(info, entry):
    if info.get("id") != entry["id"]:
        fail(entry["name"] + ": module ID mismatch: " + str(info.get("id")))
    if str(info.get("version")) != entry["expectedVersion"]:
        fail(entry["name"] + ": version mismatch; expected " + entry["expectedVersion"] + ", got " + str(info.get("version")))
    compat = info.get("compatibility") or {}
    lo = major(compat.get("minimum"))
    hi = major(compat.get("maximum"))
    if lo is None or lo > 13 or (hi is not None and hi < 13):
        fail(entry["name"] + ": module does not declare V13 compatibility: " + str(compat))
    download = info.get("download")
    if not isinstance(download, str) or not download.startswith("https://"):
        fail(entry["name"] + ": no HTTPS download URL")
    return download

def extract_safe(archive, folder):
    with zipfile.ZipFile(archive) as z:
        members = z.infolist()
        if len(members) > 75000 or sum(i.file_size for i in members) > 4 * 1024 ** 3:
            fail("ZIP exceeds entry count/expanded size limit")
        for item in members:
            name = item.filename.replace("\\", "/")
            parts = name.split("/")
            if name.startswith("/") or ".." in parts or "\x00" in name or (parts and ":" in parts[0]):
                fail("Unsafe ZIP path: " + name)
            if stat.S_IFMT(item.external_attr >> 16) == stat.S_IFLNK:
                fail("ZIP contains a symbolic link: " + name)
        z.extractall(folder)

def find_root(folder, expected):
    matches = []
    for candidate in folder.rglob("module.json"):
        try:
            metadata = json.loads(candidate.read_text(encoding="utf-8"))
            if metadata.get("id") == expected:
                matches.append((candidate.parent, metadata))
        except (OSError, UnicodeError, ValueError):
            pass
    if len(matches) != 1:
        fail("Expected one matching archive module.json for " + expected + "; found " + str(len(matches)))
    return matches[0]

def install(entry, modules, backups, update=False, check=False):
    target = modules / entry["id"]
    if target.exists() and not update and not check:
        print("SKIP (already installed):", entry["name"], "| use --update to replace")
        return
    print("Checking:", entry["name"])
    published = remote(entry["manifest"], entry["name"] + " manifest")
    url = validate(published, entry)
    if check:
        print("  OK V13 manifest:", entry["id"], entry["expectedVersion"])
        return
    with tempfile.TemporaryDirectory(prefix=".v13dependencies-", dir=modules) as temp:
        temp = Path(temp)
        archive = temp / "module.zip"
        extracted = temp / "extracted"
        extracted.mkdir()
        remote(url, entry["name"] + " archive", archive)
        extract_safe(archive, extracted)
        package_root, package_metadata = find_root(extracted, entry["id"])
        validate(package_metadata, entry)
        previous = target.exists()
        backup = backups / entry["id"]
        if previous:
            backups.mkdir(parents=True, exist_ok=True)
            if backup.exists():
                fail("Backup path exists: " + str(backup))
            target.rename(backup)
        try:
            package_root.rename(target)
            if not (target / "module.json").is_file():
                fail("Install verification failed: " + entry["id"])
        except Exception:
            if target.exists():
                shutil.rmtree(target)
            if previous:
                backup.rename(target)
            raise
    print("  INSTALLED:", entry["id"], entry["expectedVersion"], ("(backup: " + str(backup) + ")") if previous else "")

def main():
    parser = argparse.ArgumentParser(description="No-argument installer for V13 dependencies; default: install only missing modules")
    parser.add_argument("--update", action="store_true", help="Replace installed dependencies with timestamped backups")
    parser.add_argument("--check", action="store_true", help="Verify remote manifests without installing")
    args = parser.parse_args()
    root = Path(os.getenv("FOUNDRY_V13_ROOT", str(DEFAULT_ROOT))).expanduser().resolve()
    if "foundryvttv14" in str(root).lower():
        fail("Refusing to use the V14 data root for a V13 dependency install")
    modules = root / "Data" / "modules"
    if not args.check:
        modules.mkdir(parents=True, exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y-%m-%d %H%M%S %f")
    backups = root / "Data" / ".v13dependencies-backups" / stamp
    registry = json.loads((HERE / "dependencies-v13.json").read_text(encoding="utf-8"))
    if registry["foundry"]["generation"] != 13:
        fail("The dependency registry must target Foundry V13")
    print("V13 modules:", modules)
    print("Close Foundry first. No worlds, systems or campaign modules will be modified.")
    failures = 0
    for entry in registry["packages"]:
        if entry.get("installMode") != "manifest":
            continue
        try:
            install(entry, modules, backups, update=args.update, check=args.check)
        except Exception as exc:
            print("FAILED:", entry["name"], str(exc), file=sys.stderr)
            failures += 1
    print("Done; failures:", failures)
    return int(bool(failures))

if __name__ == "__main__":
    sys.exit(main())
