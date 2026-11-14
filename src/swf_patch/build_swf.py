#!/usr/bin/env python3
"""Build patched Swords and Sandals 2 Co-op SWF using FFDEC -importScript."""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import shutil
import subprocess
import sys

DEFAULT_SRC_SWF = Path(
    r"C:\Program Files (x86)\Steam\steamapps\common\Swords and Sandals Classic Collection\swf\swords_sandals2_download.swf"
)
REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUT_SWF = REPO_ROOT / "dist" / "swords_sandals2_coop.swf"
DEFAULT_SCRIPTS_PARENT = Path(__file__).resolve().parent
DEFAULT_FFDEC_JAR = REPO_ROOT / "tools" / "ffdec" / "ffdec.jar"

_ERROR_PATTERN = re.compile(
    r"(?:^\s*SEVERE\b|Exception\b|ActionScript.*error|Compile error|Syntax error|Cannot find|Failed to)",
    re.IGNORECASE | re.MULTILINE,
)


def build_swf(
    src_swf: Path = DEFAULT_SRC_SWF,
    out_swf: Path = DEFAULT_OUT_SWF,
    scripts_parent: Path = DEFAULT_SCRIPTS_PARENT,
    ffdec_jar: Path = DEFAULT_FFDEC_JAR,
) -> Path:
    src_swf = Path(src_swf).resolve()
    out_swf = Path(out_swf).resolve()
    scripts_parent = Path(scripts_parent).resolve()
    ffdec_jar = Path(ffdec_jar).resolve()

    if not src_swf.is_file():
        raise FileNotFoundError(f"Source SWF not found: {src_swf}")
    if not ffdec_jar.is_file():
        raise FileNotFoundError(f"FFDEC jar not found: {ffdec_jar}")

    scripts_dir = scripts_parent / "scripts"
    if not scripts_dir.is_dir():
        raise FileNotFoundError(f"Scripts directory not found: {scripts_dir}")

    as_files = sorted(scripts_dir.rglob("*.as"))
    if not as_files:
        raise FileNotFoundError(f"No .as patch files found under {scripts_dir}")

    out_swf.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src_swf, out_swf)

    tmp_out = out_swf.with_suffix(".tmp.swf")
    if tmp_out.exists():
        tmp_out.unlink()

    cmd = [
        "java",
        "-jar",
        str(ffdec_jar),
        "-importScript",
        str(out_swf),
        str(tmp_out),
        str(scripts_parent),
    ]
    print(f"[build_swf] Importing {len(as_files)} script(s) from {scripts_parent}:")
    for path in as_files:
        print(f"  - {path.relative_to(scripts_parent)}")

    proc = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )

    combined = "\n".join(part for part in (proc.stdout, proc.stderr) if part)
    if combined.strip():
        print(combined.strip())

    if proc.returncode != 0:
        if tmp_out.exists():
            tmp_out.unlink()
        raise RuntimeError(f"FFDEC exited with code {proc.returncode}")

    if _ERROR_PATTERN.search(combined):
        if tmp_out.exists():
            tmp_out.unlink()
        raise RuntimeError("FFDEC reported script import/compile errors (see output above)")

    if not tmp_out.is_file() or tmp_out.stat().st_size == 0:
        raise RuntimeError(f"FFDEC did not produce valid output SWF: {tmp_out}")

    shutil.move(str(tmp_out), str(out_swf))
    print(f"[build_swf] OK -> {out_swf} ({out_swf.stat().st_size} bytes)")
    return out_swf


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--src", type=Path, default=DEFAULT_SRC_SWF)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT_SWF)
    parser.add_argument("--scripts-parent", type=Path, default=DEFAULT_SCRIPTS_PARENT)
    parser.add_argument("--ffdec", type=Path, default=DEFAULT_FFDEC_JAR)
    args = parser.parse_args(argv)

    try:
        build_swf(
            src_swf=args.src,
            out_swf=args.out,
            scripts_parent=args.scripts_parent,
            ffdec_jar=args.ffdec,
        )
    except Exception as exc:
        print(f"[build_swf] ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
