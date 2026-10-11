#!/usr/bin/env python3
"""Export all installed Foundry V13 and V14 modules to Desktop JSON. Never modifies Foundry."""
import datetime, json, sys
from pathlib import Path

HOME = Path.home()
DIRECTORIES = {
  "v13": HOME / "Library" / "Application Support" / "FoundryVTT" / "Data" / "modules",
  "v14": HOME / "Library" / "Application Support" / "FoundryVTTV14" / "Data" / "modules"
}

def inventory(name, directory):
    modules, errors = [], []
    if directory.is_dir():
        for folder in sorted(directory.iterdir(), key=lambda p: p.name.lower()):
            if not folder.is_dir() or folder.name.startswith("."):
                continue
            manifest = folder / "module.json"
            if not manifest.exists():
                errors.append({"folder": folder.name, "error": "Missing module.json"})
                continue
            try:
                data = json.loads(manifest.read_text(encoding="utf-8"))
                relationships = data.get("relationships") if isinstance(data.get("relationships"), dict) else {}
                modules.append({
                    "folder": folder.name,
                    "id": data.get("id", data.get("name", folder.name)),
                    "title": data.get("title", data.get("name", folder.name)),
                    "version": data.get("version"),
                    "compatibility": data.get("compatibility", {}),
                    "manifest": data.get("manifest"),
                    "url": data.get("url"),
                    "requires": relationships.get("requires", []),
                    "recommends": relationships.get("recommends", [])
                })
            except Exception as exc:
                errors.append({"folder": folder.name, "error": str(exc)})
    return {
        "schema": 1,
        "foundryGeneration": int(name[1:]),
        "generatedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "directoryExists": directory.is_dir(),
        "installedCount": len(modules),
        "installedModules": modules,
        "errors": errors,
        "note": "Only installed packages; world-specific enabled/disabled state is not included."
    }

def main():
    desktop = HOME / "Desktop"
    desktop.mkdir(parents=True, exist_ok=True)
    for name, directory in DIRECTORIES.items():
        report = inventory(name, directory)
        output = desktop / ("foundry-" + name + "-installed-modules.json")
        output.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(name.upper(), "installed:", report["installedCount"], "|", output)
        if not report["directoryExists"]:
            print("Folder not found:", directory, file=sys.stderr)
        for err in report["errors"]:
            print("WARN", err["folder"], err["error"], file=sys.stderr)
    print("Upload foundry-v14-installed-modules.json to expand the V13 registry.")
    print("Inspect custom manifest URLs before sharing if a provider may have embedded a token.")

if __name__ == "__main__":
    main()
