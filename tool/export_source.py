"""Export complete text files and binary encodings; no shortened code excerpts."""
import base64
import re
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs/FULL_SOURCE.md"


def main():
    # Respect Git ignore rules so caches, credentials and local SDK paths stay out.
    result = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
        cwd=ROOT, check=True, capture_output=True,
    )
    paths = sorted(set(p for p in result.stdout.decode().split("\0") if p))
    sections = ["# KidSafe Launcher — full Phase 1 file contents\n\n"
                "Every project file is included in full. Binary files are encoded as base64.\n"]
    for name in paths:
        path = ROOT / name
        if path == OUTPUT or not path.is_file():
            continue
        data = path.read_bytes()
        try:
            content = data.decode("utf-8")
            kind = path.suffix.lstrip(".") or "text"
        except UnicodeDecodeError:
            content = base64.b64encode(data).decode("ascii")
            kind = "base64"
        fence = "`" * max(4, max((len(run) for run in re.findall(r'`+', content)), default=0) + 1)
        sections.append(f"\n## {name}\n\n{fence}{kind}\n{content}\n{fence}\n")
    OUTPUT.write_text("".join(sections))
    print(f"Wrote {OUTPUT} with complete contents of {len(paths)} files.")


if __name__ == "__main__":
    main()
