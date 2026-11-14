"""Independent Ruffle desktop SWF runner helper for SS2 Co-op QA."""

from __future__ import annotations

import argparse
import ctypes
from ctypes import wintypes
import os
from pathlib import Path
import subprocess
import sys
import time
from typing import IO, Iterable, Mapping, Sequence

RUNNER_DIR = Path(__file__).resolve().parent
RUFFLE_EXE = RUNNER_DIR / "ruffle.exe"
DEFAULT_SS2_SWF = Path(
    r"C:\Program Files (x86)\Steam\steamapps\common\Swords and Sandals Classic Collection\swf\swords_sandals2_download.swf"
)

user32 = ctypes.windll.user32
SWP_NOZORDER = 0x0004
SWP_NOSIZE = 0x0001
SWP_NOACTIVATE = 0x0010
_LOG_HANDLES: dict[int, tuple[list[IO[bytes]], Path | None]] = {}


def build_ruffle_command(
    swf_path: str | Path,
    *,
    width: int = 800,
    height: int = 600,
    socket_allow: Iterable[str] = (),
    tcp_connections: str | None = None,
    volume: float = 1.0,
    no_gui: bool = True,
    storage: str = "memory",
    save_directory: str | Path | None = None,
    config_directory: str | Path | None = None,
    cache_directory: str | Path | None = None,
    flashvars: Mapping[str, str] | None = None,
    extra_args: Sequence[str] = (),
) -> list[str]:
    """Build a Ruffle CLI command with explicit socket and window options."""
    if not RUFFLE_EXE.is_file():
        raise FileNotFoundError(f"Ruffle binary not found: {RUFFLE_EXE}")

    cmd: list[str] = [
        str(RUFFLE_EXE),
        "--width",
        str(width),
        "--height",
        str(height),
        "--volume",
        str(volume),
        "--storage",
        storage,
    ]
    graphics = os.environ.get("SS2_RUFFLE_GRAPHICS", "vulkan")
    if graphics and "--graphics" not in extra_args and "-g" not in extra_args:
        cmd.extend(["--graphics", graphics])
    if no_gui:
        cmd.append("--no-gui")
    if save_directory is not None:
        cmd.extend(["--save-directory", str(save_directory)])
    if config_directory is not None:
        cmd.extend(["--config", str(config_directory)])
    if cache_directory is not None:
        cmd.extend(["--cache-directory", str(cache_directory)])
    for endpoint in socket_allow:
        cmd.extend(["--socket-allow", endpoint])
    if tcp_connections is not None:
        cmd.extend(["--tcp-connections", tcp_connections])
    if flashvars:
        for key, value in flashvars.items():
            cmd.append(f"-P{key}={value}")
    cmd.extend(extra_args)
    cmd.append(str(swf_path))
    return cmd


def _open_log_target(path: str | Path | None, opened: list[IO[bytes]]) -> int | IO[bytes]:
    if path is None:
        return subprocess.DEVNULL
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    handle = open(target, "wb")
    opened.append(handle)
    return handle


def launch_client(
    swf_path: str | Path,
    *,
    width: int = 800,
    height: int = 600,
    socket_allow: Iterable[str] = (),
    tcp_connections: str | None = None,
    volume: float = 1.0,
    no_gui: bool = True,
    storage: str = "memory",
    save_directory: str | Path | None = None,
    config_directory: str | Path | None = None,
    cache_directory: str | Path | None = None,
    flashvars: Mapping[str, str] | None = None,
    stdout_path: str | Path | None = None,
    stderr_path: str | Path | None = None,
    extra_args: Sequence[str] = (),
) -> subprocess.Popen[bytes]:
    """Launch a single windowed Ruffle instance without blocking on PIPE buffers."""
    cmd = build_ruffle_command(
        swf_path,
        width=width,
        height=height,
        socket_allow=socket_allow,
        tcp_connections=tcp_connections,
        volume=volume,
        no_gui=no_gui,
        storage=storage,
        save_directory=save_directory,
        config_directory=config_directory,
        cache_directory=cache_directory,
        flashvars=flashvars,
        extra_args=extra_args,
    )
    opened: list[IO[bytes]] = []
    try:
        stdout_target = _open_log_target(stdout_path, opened)
        stderr_target = _open_log_target(stderr_path, opened)
        proc = subprocess.Popen(cmd, stdout=stdout_target, stderr=stderr_target)
    except Exception:
        for handle in opened:
            handle.close()
        raise
    if opened or stderr_path is not None:
        _LOG_HANDLES[id(proc)] = (opened, Path(stderr_path) if stderr_path is not None else None)
    return proc


def find_visible_windows(pids: set[int]) -> dict[int, list[tuple[int, str]]]:
    """Return visible Win32 top-level windows keyed by PID."""
    found: dict[int, list[tuple[int, str]]] = {}

    @ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)
    def enum_cb(hwnd: int, _lparam: int) -> bool:
        if user32.IsWindowVisible(hwnd):
            pid = wintypes.DWORD()
            user32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
            if pid.value in pids:
                buf = ctypes.create_unicode_buffer(256)
                user32.GetWindowTextW(hwnd, buf, 256)
                found.setdefault(pid.value, []).append((hwnd, buf.value))
        return True

    user32.EnumWindows(enum_cb, 0)
    return found


def _read_stderr_summary(proc: subprocess.Popen[bytes]) -> str:
    if proc.stderr is not None:
        _, err = proc.communicate(timeout=2)
        return err.decode(errors="replace") if err else ""
    entry = _LOG_HANDLES.get(id(proc))
    if entry is not None and entry[1] is not None and entry[1].is_file():
        return entry[1].read_text(encoding="utf-8", errors="replace")[-1000:]
    return "(stderr redirected to DEVNULL)"


def wait_for_windows(
    procs: Sequence[subprocess.Popen[bytes]],
    *,
    timeout: float = 10.0,
    poll_interval: float = 0.1,
) -> dict[int, list[tuple[int, str]]]:
    """Wait until every process has at least one titled visible window."""
    pids = {p.pid for p in procs}
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        for p in procs:
            if p.poll() is not None:
                err_msg = _read_stderr_summary(p)
                raise RuntimeError(
                    f"Ruffle process {p.pid} exited early with code {p.returncode}: {err_msg}"
                )
        windows = find_visible_windows(pids)
        if all(
            any(title.strip() for _, title in windows.get(pid, ()))
            for pid in pids
        ):
            return windows
        time.sleep(poll_interval)
    raise TimeoutError(f"Timed out waiting for Ruffle windows for PIDs {sorted(pids)}")


def position_window(hwnd: int, x: int, y: int) -> None:
    """Move a Win32 window without resizing, activating, or changing Z-order."""
    user32.SetWindowPos(hwnd, 0, x, y, 0, 0, SWP_NOZORDER | SWP_NOSIZE | SWP_NOACTIVATE)


def terminate_processes(
    procs: Sequence[subprocess.Popen[bytes]],
    *,
    timeout: float = 5.0,
) -> None:
    """Gracefully terminate Ruffle processes, falling back to kill."""
    for p in procs:
        if p.poll() is None:
            p.terminate()
    for p in procs:
        try:
            p.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            p.kill()
            p.wait(timeout=timeout)
        for stream in (p.stdout, p.stderr):
            if stream is not None:
                stream.close()
        entry = _LOG_HANDLES.pop(id(p), None)
        if entry is not None:
            for handle in entry[0]:
                handle.close()


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Launch 1 or 2 windowed SS2 Ruffle clients.")
    parser.add_argument("swf", nargs="?", default=str(DEFAULT_SS2_SWF), help="Path to SWF file")
    parser.add_argument("--pair", action="store_true", help="Launch 2 side-by-side windows")
    parser.add_argument("--width", type=int, default=720)
    parser.add_argument("--height", type=int, default=540)
    parser.add_argument("--volume", type=float, default=0.5)
    parser.add_argument("--socket-allow", action="append", default=[], dest="socket_allow")
    args = parser.parse_args(argv)

    count = 2 if args.pair else 1
    procs = [
        launch_client(
            args.swf,
            width=args.width,
            height=args.height,
            volume=args.volume,
            socket_allow=args.socket_allow,
        )
        for _ in range(count)
    ]
    try:
        windows = wait_for_windows(procs)
        if args.pair:
            for idx, p in enumerate(procs):
                for hwnd, title in windows.get(p.pid, ()):
                    if title.strip():
                        position_window(hwnd, 20 + idx * (args.width + 20), 40)
                        break
        for p in procs:
            p.wait()
    except KeyboardInterrupt:
        pass
    finally:
        terminate_processes(procs)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
