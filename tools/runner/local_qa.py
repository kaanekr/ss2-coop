"""Run two local SS2 Co-op clients with an isolated Ruffle and relay session."""

from __future__ import annotations

import argparse
from collections.abc import Iterator
from contextlib import ExitStack, contextmanager
import json
import math
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile
import time
from typing import Any

import runner

PROJECT_ROOT = Path(__file__).resolve().parents[2]
COOP_SWF = PROJECT_ROOT / "dist" / "swords_sandals2_coop.swf"
RELAY_SCRIPT = PROJECT_ROOT / "src" / "relay" / "ss2_coop_relay.py"
RUNS_DIR = PROJECT_ROOT / "local" / "qa_runs"
Session = tuple[subprocess.Popen[bytes], list[subprocess.Popen[bytes]], int, Path]


class ClientConnectionTimeout(TimeoutError):
    """The two clients did not both connect during startup."""


def control_request(port: int, request: dict[str, Any], timeout: float = 3.0) -> dict[str, Any]:
    """Send a JSON-line request to the local relay."""
    with socket.create_connection(("127.0.0.1", port), timeout=timeout) as sock:
        sock.sendall((json.dumps(request) + "\n").encode("utf-8"))
        with sock.makefile("rb") as response:
            return json.loads(response.readline())


def wait_for_relay(relay: subprocess.Popen[bytes], event_log: Path) -> dict[str, int]:
    """Read the actual listen ports from the relay's startup event."""
    deadline = time.monotonic() + 6
    while time.monotonic() < deadline:
        if relay.poll() is not None:
            raise RuntimeError(f"Relay exited with code {relay.returncode}. See {event_log.with_name('relay.log')}")
        if event_log.is_file():
            with event_log.open(encoding="utf-8") as events:
                for line in events:
                    if line.endswith("\n"):
                        event = json.loads(line)
                        if event["event"] == "started":
                            return event["ports"]
        time.sleep(0.05)
    raise TimeoutError(f"Relay did not start. See {event_log.with_name('relay.log')}")


def stop_relay(relay: subprocess.Popen[bytes], control_port: int | None) -> None:
    if relay.poll() is not None:
        return
    if control_port is not None:
        try:
            control_request(control_port, {"cmd": "shutdown"}, timeout=1)
            relay.wait(timeout=3)
            return
        except (OSError, ValueError, subprocess.TimeoutExpired):
            pass
    relay.terminate()
    relay.wait(timeout=5)


@contextmanager
def _launch_session(
    swf: Path,
    *,
    automated: bool,
    quick_lobby: bool,
    latency_ms: float,
    drop_rate: float,
    ephemeral_ports: bool,
) -> Iterator[Session]:
    """Launch and clean up one relay and two Ruffle windows."""
    swf = swf.resolve(strict=True)
    if not swf.is_file():
        raise ValueError(f"Expected a SWF file: {swf}")
    if not runner.RUFFLE_EXE.is_file():
        raise FileNotFoundError(f"Ruffle binary not found: {runner.RUFFLE_EXE}")

    RUNS_DIR.mkdir(parents=True, exist_ok=True)
    log_dir = Path(tempfile.mkdtemp(prefix="session-", dir=RUNS_DIR))
    event_log = log_dir / "events.jsonl"
    print(f"QA logs: {log_dir}", flush=True)

    # Manual lobby buttons use fixed ports. Automated tests connect using FlashVars.
    relay_cmd = [
        sys.executable,
        str(RELAY_SCRIPT),
        "local-pair",
        "--host-port", "0" if ephemeral_ports else "19801",
        "--client-port", "0" if ephemeral_ports else "19802",
        "--control-port", "0",
        "--latency-ms", str(latency_ms),
        "--drop-rate", str(drop_rate),
        "--history-size", "400",
        "--event-log", str(event_log),
    ]
    with (log_dir / "relay.log").open("wb") as relay_log:
        relay = subprocess.Popen(
            relay_cmd,
            stdout=relay_log,
            stderr=subprocess.STDOUT,
            creationflags=subprocess.CREATE_NO_WINDOW,
        )

    procs: list[subprocess.Popen[bytes]] = []
    control_port = None
    try:
        ports = wait_for_relay(relay, event_log)
        control_port = ports["control"]
        for role in ("host", "client"):
            port = ports[role]
            shared_cache = RUNS_DIR / "_shared_cache" / role
            dll_rel = Path("video") / "openh264-2.7.0-win64.dll"
            target_dll = shared_cache / dll_rel
            if not target_dll.is_file():
                seed_dll = RUNS_DIR / "session-qwj8jl4y" / "host" / "cache" / dll_rel
                if seed_dll.is_file():
                    target_dll.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(seed_dll, target_dll)
            flashvars = None
            if automated or quick_lobby:
                flashvars = {
                    "coopRole": role,
                    "coopPort": str(port),
                    "coopAuto": "auto_duel" if automated else "1",
                    "coopTest": "1",
                }
            proc = runner.launch_client(
                swf,
                width=640,
                height=480,
                volume=0.0,
                socket_allow=[f"127.0.0.1:{port}"],
                tcp_connections="deny",
                config_directory=log_dir / role / "config",
                cache_directory=shared_cache,
                stdout_path=log_dir / role / "stdout.log",
                stderr_path=log_dir / role / "stderr.log",
                flashvars=flashvars,
            )
            procs.append(proc)
            if role == "host":
                time.sleep(0.25)

        windows = runner.wait_for_windows(procs, timeout=12)
        for idx, proc in enumerate(procs):
            hwnd = next(handle for handle, title in windows[proc.pid] if title.strip())
            runner.position_window(hwnd, 20 + idx * 660, 40)
        print(
            f"Host (left): {ports['host']}, Client (right): {ports['client']}, control: {control_port}",
            flush=True,
        )
        if automated or quick_lobby:
            deadline = time.monotonic() + 8
            while True:
                status = control_request(control_port, {"cmd": "status"})
                endpoints = status["endpoints"]
                waiting = [
                    role for role in ("host", "client")
                    if not endpoints[f"{role}_xml"]["connected"]
                ]
                if not waiting:
                    break
                if time.monotonic() >= deadline:
                    raise ClientConnectionTimeout(f"{', '.join(waiting)} did not connect. See {log_dir}.")
                time.sleep(0.1)
        if quick_lobby:
            for role in ("host", "client"):
                reply = control_request(
                    control_port,
                    {"cmd": "inject", "target": f"{role}_xml", "payload": "COOP|t=qa|cmd=quick_char"},
                )
                if not reply.get("ok"):
                    raise ClientConnectionTimeout(f"{role} disconnected before character creation. See {log_dir}.")
        yield relay, procs, control_port, event_log
    finally:
        try:
            runner.terminate_processes(procs)
        finally:
            stop_relay(relay, control_port)


@contextmanager
def launch_pair(
    swf: Path = COOP_SWF,
    *,
    automated: bool = False,
    quick_lobby: bool = False,
    latency_ms: float = 0,
    drop_rate: float = 0,
    ephemeral_ports: bool = False,
) -> Iterator[Session]:
    """Restart once if the clients time out connecting during startup."""
    with ExitStack() as stack:
        for attempt in range(2):
            try:
                session = stack.enter_context(
                    _launch_session(
                        swf,
                        automated=automated,
                        quick_lobby=quick_lobby,
                        latency_ms=latency_ms,
                        drop_rate=drop_rate,
                        ephemeral_ports=automated or ephemeral_ports,
                    )
                )
            except ClientConnectionTimeout as exc:
                if attempt == 1:
                    raise
                print(f"{exc} Retrying with a fresh session.", file=sys.stderr, flush=True)
            else:
                yield session
                return


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--swf", type=Path, default=COOP_SWF, help="Patched SS2 SWF to play")
    parser.add_argument("--lobby", action="store_true", help="Skip the tutorial with two QA gladiators")
    parser.add_argument("--latency-ms", type=float, default=0, help="One-way relay latency")
    parser.add_argument("--drop-rate", type=float, default=0, help="Packet drop probability (0 to 1)")
    args = parser.parse_args()
    if not math.isfinite(args.latency_ms) or args.latency_ms < 0:
        parser.error("--latency-ms must be a finite non-negative number")
    if not 0 <= args.drop_rate <= 1:
        parser.error("--drop-rate must be between 0 and 1")
    try:
        with launch_pair(
            args.swf,
            quick_lobby=args.lobby,
            latency_ms=args.latency_ms,
            drop_rate=args.drop_rate,
        ) as session:
            relay, procs, _, _ = session
            print("Close either game window or press Ctrl+C to end the QA session.", flush=True)
            while relay.poll() is None:
                for proc in procs:
                    if proc.poll() is not None:
                        return proc.returncode
                time.sleep(0.2)
            raise RuntimeError(f"Relay exited with code {relay.returncode}.")
    except KeyboardInterrupt:
        return 0
    except (OSError, RuntimeError, ValueError) as exc:
        print(f"Local QA failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
