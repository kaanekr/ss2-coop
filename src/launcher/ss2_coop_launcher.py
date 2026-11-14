#!/usr/bin/env python3
"""Player-facing Tailscale Co-op Launcher (Tkinter GUI + CLI fallback) for Swords and Sandals 2."""

from __future__ import annotations

import argparse
import atexit
from collections import deque
import json
import os
from pathlib import Path
import re
import signal
import socket
import subprocess
import sys
import threading
import time
from typing import Any

PROJECT_ROOT = Path(__file__).resolve().parents[2]
RELAY_DIR = PROJECT_ROOT / "src" / "relay"
RELAY_SCRIPT = RELAY_DIR / "ss2_coop_relay.py"
if str(RELAY_DIR) not in sys.path:
    sys.path.insert(0, str(RELAY_DIR))

from ss2_coop_relay import (  # noqa: E402
    DEFAULT_CLIENT_LOCAL_PORT,
    DEFAULT_HOST_LOCAL_PORT,
    DEFAULT_PEER_PORT,
    TailscaleInfo,
    detect_tailscale_ipv4,
    parse_host_port,
)

STEAM_APP_ID = "1055430"
GAME_FOLDER_NAME = "Swords and Sandals Classic Collection"
GAME_EXE_NAME = "Swords and Sandals Classic Collection.exe"
_CTRL_PORT_RE = re.compile(r"Control TCP server listening on [^:]+:(\d+)")
_VDF_PATH_RE = re.compile(r'"path"\s+"([^"]+)"', re.IGNORECASE)
_ADDR_IN_USE_RE = re.compile(r"(10048|EADDRINUSE|address already in use)", re.IGNORECASE)


class PortInUseError(RuntimeError):
    """Raised when a required Co-op relay TCP port is already bound by another process."""

    def __init__(self, port: int, mode: str, detail: str = "") -> None:
        self.port = port
        self.mode = mode
        self.detail = detail
        role_label = "Host" if mode == "host" else "Join"
        msg = (
            f"Co-op {role_label} Relay zaten açık / port {port} kullanımda.\n"
            f"(Co-op {role_label} Relay is already running or port {port} is in use.)\n\n"
            "Mevcut açık relay ile devam edip oyunu başlatabilir, veya açık olan relay/launcher penceresini kapatıp tekrar deneyebilirsin."
        )
        super().__init__(msg)


def is_tcp_port_listening(host: str, port: int, timeout: float = 0.2) -> bool:
    """Return True if a TCP listener is actively accepting connections on ``host:port``."""
    probe_host = "127.0.0.1" if host in ("0.0.0.0", "", "::") else host
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.settimeout(timeout)
            return sock.connect_ex((probe_host, int(port))) == 0
    except OSError:
        return False


def free_tcp_ports(ports: tuple[int, ...]) -> list[int]:
    """Terminate stale Windows processes listening on ``ports`` before starting a relay."""
    if not sys.platform.startswith("win"):
        return []
    busy_ports = {int(p) for p in ports if is_tcp_port_listening("127.0.0.1", int(p))}
    if not busy_ports:
        return []
    creationflags = getattr(subprocess, "CREATE_NO_WINDOW", 0)
    try:
        proc = subprocess.run(
            ["netstat", "-ano", "-p", "tcp"],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=3,
            creationflags=creationflags,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return []

    target_pids: list[int] = []
    self_pid = os.getpid()
    for line in proc.stdout.splitlines():
        parts = line.split()
        if len(parts) < 5 or parts[0].upper() != "TCP":
            continue
        local_addr, foreign_addr = parts[1], parts[2]
        local_port_str = local_addr.rsplit(":", 1)[-1]
        if not local_port_str.isdigit() or int(local_port_str) not in busy_ports:
            continue
        is_listener = foreign_addr in ("0.0.0.0:0", "[::]:0") or "LISTEN" in line.upper()
        if not is_listener:
            continue
        try:
            pid = int(parts[-1])
        except ValueError:
            continue
        if pid > 0 and pid != self_pid and pid not in target_pids:
            target_pids.append(pid)

    killed: list[int] = []
    for pid in target_pids:
        try:
            res = subprocess.run(
                ["taskkill", "/F", "/T", "/PID", str(pid)],
                capture_output=True,
                text=True,
                timeout=3,
                creationflags=creationflags,
                check=False,
            )
            if res.returncode == 0:
                killed.append(pid)
        except (OSError, subprocess.SubprocessError):
            continue

    if killed:
        deadline = time.monotonic() + 1.0
        while time.monotonic() < deadline:
            if not any(is_tcp_port_listening("127.0.0.1", p) for p in busy_ports):
                break
            time.sleep(0.05)
    return killed


def find_steam_game_dir() -> Path | None:
    """Locate the Steam installation of Swords and Sandals Classic Collection."""
    candidates: list[Path] = [
        Path(r"C:\Program Files (x86)\Steam\steamapps\common") / GAME_FOLDER_NAME,
        Path(r"C:\Program Files\Steam\steamapps\common") / GAME_FOLDER_NAME,
    ]

    steam_roots: list[Path] = [
        Path(r"C:\Program Files (x86)\Steam"),
        Path(r"C:\Program Files\Steam"),
    ]
    if sys.platform.startswith("win"):
        try:
            import winreg

            for hkey, subkey, valname in (
                (winreg.HKEY_CURRENT_USER, r"Software\Valve\Steam", "SteamPath"),
                (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\WOW6432Node\Valve\Steam", "InstallPath"),
                (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Valve\Steam", "InstallPath"),
            ):
                try:
                    with winreg.OpenKey(hkey, subkey) as key:
                        val, _ = winreg.QueryValueEx(key, valname)
                        if val:
                            steam_roots.append(Path(val))
                except OSError:
                    continue
        except ImportError:
            pass

    seen_roots: set[Path] = set()
    for sroot in steam_roots:
        if sroot in seen_roots:
            continue
        seen_roots.add(sroot)
        candidates.append(sroot / "steamapps" / "common" / GAME_FOLDER_NAME)
        vdf = sroot / "steamapps" / "libraryfolders.vdf"
        if vdf.is_file():
            try:
                text = vdf.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            for raw_lib in _VDF_PATH_RE.findall(text):
                lib_path = Path(raw_lib.replace("\\\\", "\\"))
                candidates.append(lib_path / "steamapps" / "common" / GAME_FOLDER_NAME)

    for candidate in candidates:
        if (candidate / "swf" / "swords_sandals2_download.swf").is_file():
            return candidate
    return None


def launch_steam_game(game_dir: Path | None = None) -> tuple[bool, str]:
    """Launch Swords and Sandals Classic Collection via Steam URI or executable."""
    if sys.platform.startswith("win"):
        try:
            os.startfile(f"steam://rungameid/{STEAM_APP_ID}")  # type: ignore[attr-defined]
            return True, f"Launched via steam://rungameid/{STEAM_APP_ID}"
        except OSError:
            pass
    if game_dir is not None:
        exe = game_dir / GAME_EXE_NAME
        if exe.is_file():
            subprocess.Popen([str(exe)], cwd=str(game_dir))
            return True, f"Launched {exe}"
    return False, "Could not launch Steam game automatically; launch it from Steam manually."


class RelayProcessManager:
    """Manages a child ``ss2_coop_relay.py`` process and queries its control port."""

    def __init__(self, relay_script: Path = RELAY_SCRIPT) -> None:
        self.relay_script = Path(relay_script)
        self._proc: subprocess.Popen[str] | None = None
        self._control_port: int | None = None
        self._mode: str | None = None
        self._logs: deque[str] = deque(maxlen=250)
        self._lock = threading.Lock()
        self._threads: list[threading.Thread] = []
        atexit.register(self.stop)

    @property
    def is_running(self) -> bool:
        return self._proc is not None and self._proc.poll() is None

    @property
    def control_port(self) -> int | None:
        return self._control_port

    @property
    def mode(self) -> str | None:
        return self._mode

    def recent_logs(self) -> list[str]:
        with self._lock:
            return list(self._logs)

    def _drain_stream(self, stream: Any, prefix: str = "") -> None:
        try:
            for raw_line in iter(stream.readline, ""):
                line = raw_line.rstrip("\r\n")
                if not line:
                    continue
                match = _CTRL_PORT_RE.search(line)
                if match:
                    self._control_port = int(match.group(1))
                with self._lock:
                    self._logs.append(f"{prefix}{line}")
        except (OSError, ValueError):
            pass
        finally:
            try:
                stream.close()
            except OSError:
                pass

    def start_host(
        self,
        *,
        peer_host: str = "0.0.0.0",
        peer_port: int = DEFAULT_PEER_PORT,
        local_host: str = "127.0.0.1",
        local_port: int = DEFAULT_HOST_LOCAL_PORT,
        advertise_ip: str | None = None,
        control_port: int = 0,
    ) -> int:
        if not (self.is_running and self.mode == "host"):
            free_tcp_ports((local_port, peer_port))
            for check_host, check_port in ((local_host, local_port), (peer_host, peer_port)):
                if is_tcp_port_listening(check_host, check_port):
                    raise PortInUseError(check_port, "host")

        cmd = [
            sys.executable,
            str(self.relay_script),
            "host",
            "--peer-host",
            peer_host,
            "--peer-port",
            str(peer_port),
            "--local-host",
            local_host,
            "--local-port",
            str(local_port),
            "--control-port",
            str(control_port),
        ]
        if advertise_ip:
            cmd.extend(["--advertise-ip", advertise_ip])
        return self._start(cmd, mode="host", checked_ports=(local_port, peer_port))

    def start_join(
        self,
        connect_target: str,
        *,
        local_host: str = "127.0.0.1",
        local_port: int = DEFAULT_CLIENT_LOCAL_PORT,
        control_port: int = 0,
    ) -> int:
        host, port = parse_host_port(connect_target, default_port=DEFAULT_PEER_PORT)
        if not (self.is_running and self.mode == "join"):
            free_tcp_ports((local_port,))
            if is_tcp_port_listening(local_host, local_port):
                raise PortInUseError(local_port, "join")

        normalized = f"[{host}]:{port}" if ":" in host else f"{host}:{port}"
        cmd = [
            sys.executable,
            str(self.relay_script),
            "join",
            "--connect",
            normalized,
            "--local-host",
            local_host,
            "--local-port",
            str(local_port),
            "--control-port",
            str(control_port),
        ]
        return self._start(cmd, mode="join", checked_ports=(local_port,))

    def _start(
        self,
        cmd: list[str],
        *,
        mode: str,
        checked_ports: tuple[int, ...] = (),
    ) -> int:
        self.stop()
        with self._lock:
            self._logs.clear()
        self._control_port = None
        self._mode = mode

        creationflags = getattr(subprocess, "CREATE_NO_WINDOW", 0) if sys.platform.startswith("win") else 0
        self._proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            errors="replace",
            bufsize=1,
            creationflags=creationflags,
        )
        assert self._proc.stdout is not None and self._proc.stderr is not None
        t_out = threading.Thread(target=self._drain_stream, args=(self._proc.stdout, ""), daemon=True)
        t_err = threading.Thread(
            target=self._drain_stream, args=(self._proc.stderr, "[stderr] "), daemon=True
        )
        t_out.start()
        t_err.start()
        self._threads = [t_out, t_err]

        deadline = time.monotonic() + 5.0
        while time.monotonic() < deadline:
            if self._control_port is not None:
                return self._control_port
            if self._proc.poll() is not None:
                rc = self._proc.returncode
                # Give stream drainers a tiny moment to flush final stderr lines.
                time.sleep(0.05)
                logs = "\n".join(self.recent_logs())
                self.stop()
                if _ADDR_IN_USE_RE.search(logs):
                    fallback_port = checked_ports[0] if checked_ports else DEFAULT_HOST_LOCAL_PORT
                    port_match = re.search(r",\s*(\d+)\)", logs)
                    in_use_port = int(port_match.group(1)) if port_match else fallback_port
                    raise PortInUseError(in_use_port, mode, detail=logs)
                raise RuntimeError(f"Relay exited early (code {rc}):\n{logs}")
            time.sleep(0.02)

        self.stop()
        raise TimeoutError("Timed out waiting for relay control port startup.")

    def send_control(self, cmd: str | dict[str, Any], timeout: float = 1.5) -> dict[str, Any] | None:
        port = self._control_port
        if port is None or not self.is_running:
            return None
        payload = cmd if isinstance(cmd, str) else json.dumps(cmd)
        try:
            with socket.create_connection(("127.0.0.1", port), timeout=timeout) as sock:
                sock.settimeout(timeout)
                sock.sendall((payload + "\n").encode("utf-8"))
                chunks: list[bytes] = []
                while True:
                    data = sock.recv(4096)
                    if not data:
                        break
                    chunks.append(data)
                    if b"\n" in data:
                        break
            line = b"".join(chunks).split(b"\n", 1)[0].decode("utf-8", errors="replace").strip()
            return json.loads(line) if line else None
        except (OSError, json.JSONDecodeError):
            return None

    def query_status(self) -> dict[str, Any] | None:
        return self.send_control("status")

    def stop(self) -> None:
        proc = self._proc
        if proc is None:
            return
        try:
            if proc.poll() is None:
                self.send_control("shutdown", timeout=0.8)
                try:
                    proc.wait(timeout=2.0)
                except subprocess.TimeoutExpired:
                    proc.terminate()
                    try:
                        proc.wait(timeout=2.0)
                    except subprocess.TimeoutExpired:
                        proc.kill()
                        proc.wait(timeout=2.0)
        finally:
            self._proc = None
            self._control_port = None
            self._mode = None


def format_status_summary(status: dict[str, Any] | None, mode: str | None) -> dict[str, str]:
    """Extract concise UI strings from a relay ``status`` JSON response."""
    if not status or not status.get("ok"):
        return {
            "relay": "Stopped" if mode is None else f"Starting ({mode})...",
            "peer": "Disconnected",
            "local": "Not connected",
            "relayed": "0",
        }
    endpoints = status.get("endpoints", {})
    peer_ep = endpoints.get("peer", {})
    local_ep = endpoints.get("host_xml") or endpoints.get("client_xml") or {}
    stats = status.get("stats", {})

    peer_peers = peer_ep.get("peers") or []
    peer_str = f"Connected ({peer_peers[0]})" if peer_ep.get("connected") and peer_peers else (
        "Connected" if peer_ep.get("connected") else "Waiting for peer..."
    )
    local_str = (
        f"Connected ({local_ep.get('connection_count', 1)})"
        if local_ep.get("connected")
        else "Waiting for game..."
    )
    return {
        "relay": f"Running ({status.get('mode', mode)})",
        "peer": peer_str,
        "local": local_str,
        "relayed": str(stats.get("relayed_count", 0)),
    }


def launch_gui() -> int:
    """Launch the Tkinter Co-op Launcher GUI."""
    import tkinter as tk
    from tkinter import messagebox, scrolledtext, ttk

    root = tk.Tk()
    root.title("Swords and Sandals 2 — Tailscale Co-op Launcher")
    root.geometry("620x520")
    root.minsize(560, 460)

    manager = RelayProcessManager()
    game_dir = find_steam_game_dir()
    ts_info: TailscaleInfo = detect_tailscale_ipv4()
    seen_log_count = 0

    main_frame = ttk.Frame(root, padding=12)
    main_frame.pack(fill=tk.BOTH, expand=True)

    # --- Tailscale Identity ---
    ts_frame = ttk.LabelFrame(main_frame, text="Your Tailscale Address", padding=10)
    ts_frame.pack(fill=tk.X, pady=(0, 8))

    share_var = tk.StringVar(value=f"{ts_info.ip}:{DEFAULT_PEER_PORT}")
    ts_source_var = tk.StringVar(
        value=f"Detected via {ts_info.source}"
        if ts_info.detected
        else "Tailscale IP not detected (check Tailscale is connected)"
    )

    ttk.Label(ts_frame, text="Share with friend:").grid(row=0, column=0, sticky=tk.W, padx=(0, 8))
    share_entry = ttk.Entry(ts_frame, textvariable=share_var, width=28, state="readonly")
    share_entry.grid(row=0, column=1, sticky=tk.W)

    def copy_ip() -> None:
        root.clipboard_clear()
        root.clipboard_append(share_var.get())
        root.update_idletasks()
        ts_source_var.set(f"Copied '{share_var.get()}' to clipboard!")

    def refresh_ip() -> None:
        info = detect_tailscale_ipv4()
        share_var.set(f"{info.ip}:{peer_port_var.get() or DEFAULT_PEER_PORT}")
        ts_source_var.set(
            f"Detected via {info.source}"
            if info.detected
            else "Tailscale IP not detected (check Tailscale is connected)"
        )

    ttk.Button(ts_frame, text="Copy IP:Port", command=copy_ip).grid(row=0, column=2, padx=(8, 4))
    ttk.Button(ts_frame, text="Refresh", command=refresh_ip).grid(row=0, column=3, padx=(4, 0))
    ttk.Label(ts_frame, textvariable=ts_source_var).grid(
        row=1, column=0, columnspan=4, sticky=tk.W, pady=(4, 0)
    )

    # --- Host / Join Controls ---
    actions_frame = ttk.Frame(main_frame)
    actions_frame.pack(fill=tk.X, pady=(0, 8))

    host_frame = ttk.LabelFrame(actions_frame, text="Host Co-op (P1)", padding=10)
    host_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=(0, 6))

    peer_port_var = tk.StringVar(value=str(DEFAULT_PEER_PORT))
    host_local_port_var = tk.StringVar(value=str(DEFAULT_HOST_LOCAL_PORT))
    ttk.Label(host_frame, text="Peer TCP Port:").grid(row=0, column=0, sticky=tk.W)
    ttk.Entry(host_frame, textvariable=peer_port_var, width=10).grid(row=0, column=1, sticky=tk.W, padx=6)
    ttk.Label(host_frame, text="Game XML Port:").grid(row=1, column=0, sticky=tk.W, pady=(4, 0))
    ttk.Entry(host_frame, textvariable=host_local_port_var, width=10).grid(
        row=1, column=1, sticky=tk.W, padx=6, pady=(4, 0)
    )

    join_frame = ttk.LabelFrame(actions_frame, text="Join Co-op (P2)", padding=10)
    join_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=(6, 0))

    connect_var = tk.StringVar(value=f"100.x.y.z:{DEFAULT_PEER_PORT}")
    join_local_port_var = tk.StringVar(value=str(DEFAULT_CLIENT_LOCAL_PORT))
    ttk.Label(join_frame, text="Host IP:Port:").grid(row=0, column=0, sticky=tk.W)
    ttk.Entry(join_frame, textvariable=connect_var, width=20).grid(row=0, column=1, sticky=tk.W, padx=6)
    ttk.Label(join_frame, text="Game XML Port:").grid(row=1, column=0, sticky=tk.W, pady=(4, 0))
    ttk.Entry(join_frame, textvariable=join_local_port_var, width=10).grid(
        row=1, column=1, sticky=tk.W, padx=6, pady=(4, 0)
    )

    # --- Status ---
    status_frame = ttk.LabelFrame(main_frame, text="Live Relay Status", padding=10)
    status_frame.pack(fill=tk.X, pady=(0, 8))

    relay_state_var = tk.StringVar(value="Stopped")
    peer_state_var = tk.StringVar(value="Disconnected")
    local_state_var = tk.StringVar(value="Not connected")
    relayed_var = tk.StringVar(value="0")

    for idx, (label, var) in enumerate(
        (
            ("Relay:", relay_state_var),
            ("Remote Peer:", peer_state_var),
            ("Local Game:", local_state_var),
            ("Relayed Frames:", relayed_var),
        )
    ):
        row, col = divmod(idx, 2)
        ttk.Label(status_frame, text=label).grid(row=row, column=col * 2, sticky=tk.W, padx=(0, 6))
        ttk.Label(status_frame, textvariable=var, width=26).grid(
            row=row, column=col * 2 + 1, sticky=tk.W, padx=(0, 12)
        )

    # --- Log box ---
    log_box = scrolledtext.ScrolledText(main_frame, height=10, state="disabled")
    log_box.pack(fill=tk.BOTH, expand=True)

    def append_log(text: str) -> None:
        log_box.configure(state="normal")
        log_box.insert(tk.END, text + "\n")
        log_box.see(tk.END)
        log_box.configure(state="disabled")

    def on_host() -> None:
        nonlocal seen_log_count
        try:
            p_port = int(peer_port_var.get().strip())
            l_port = int(host_local_port_var.get().strip())
            if manager.is_running and manager.mode == "host":
                if messagebox.askyesno(
                    "Host Relay Zaten Açık / Already Running",
                    f"Co-op Host Relay zaten açık (127.0.0.1:{l_port} <-> 0.0.0.0:{p_port}).\n\n"
                    "Mevcut relay ile oyunu Steam'den başlatmak ister misin?\n"
                    "(Launch Swords and Sandals 2 using the existing relay?)",
                ):
                    on_launch_game()
                return
            seen_log_count = 0
            manager.start_host(peer_port=p_port, local_port=l_port)
            refresh_ip()
            append_log(f"Started Host relay (local {l_port} <-> peer {p_port}). Open Co-op Lobby -> Host Co-op ({l_port}).")
        except PortInUseError as exc:
            append_log(f"[warning] Port {exc.port} already in use.")
            if messagebox.askyesno(
                "Port Kullanımda / Relay Zaten Açık",
                f"{exc}\n\nMevcut açık relay ile oyunu şimdi başlatmak ister misin?",
            ):
                on_launch_game()
        except Exception as exc:
            messagebox.showerror("Host Relay Error", str(exc))

    def on_join() -> None:
        nonlocal seen_log_count
        try:
            target = connect_var.get().strip()
            if "x.y.z" in target or not target:
                raise ValueError("Enter your friend's Tailscale IP:port (e.g. 100.91.119.94:19850).")
            l_port = int(join_local_port_var.get().strip())
            if manager.is_running and manager.mode == "join":
                if messagebox.askyesno(
                    "Join Relay Zaten Açık / Already Running",
                    f"Co-op Join Relay zaten açık (127.0.0.1:{l_port}).\n\n"
                    "Mevcut relay ile oyunu Steam'den başlatmak ister misin?\n"
                    "(Launch Swords and Sandals 2 using the existing relay?)",
                ):
                    on_launch_game()
                return
            seen_log_count = 0
            manager.start_join(target, local_port=l_port)
            append_log(f"Started Join relay (local {l_port} <-> {target}). Open Co-op Lobby -> Join Co-op ({l_port}).")
        except PortInUseError as exc:
            append_log(f"[warning] Port {exc.port} already in use.")
            if messagebox.askyesno(
                "Port Kullanımda / Relay Zaten Açık",
                f"{exc}\n\nMevcut açık relay ile oyunu şimdi başlatmak ister misin?",
            ):
                on_launch_game()
        except Exception as exc:
            messagebox.showerror("Join Relay Error", str(exc))

    def on_stop() -> None:
        manager.stop()
        relay_state_var.set("Stopped")
        peer_state_var.set("Disconnected")
        local_state_var.set("Not connected")
        append_log("Relay stopped.")

    def on_launch_game() -> None:
        ok, msg = launch_steam_game(game_dir)
        append_log(msg)
        if not ok:
            messagebox.showwarning("Launch Game", msg)

    ttk.Button(host_frame, text="Host Co-op", command=on_host).grid(
        row=2, column=0, columnspan=2, sticky=tk.EW, pady=(8, 0)
    )
    ttk.Button(join_frame, text="Join Co-op", command=on_join).grid(
        row=2, column=0, columnspan=2, sticky=tk.EW, pady=(8, 0)
    )

    btn_bar = ttk.Frame(main_frame)
    btn_bar.pack(fill=tk.X, pady=(8, 0))
    ttk.Button(btn_bar, text="Stop Relay", command=on_stop).pack(side=tk.LEFT)
    ttk.Button(btn_bar, text="Launch SS2 (Steam)", command=on_launch_game).pack(side=tk.RIGHT)

    def poll_status() -> None:
        nonlocal seen_log_count
        logs = manager.recent_logs()
        if len(logs) > seen_log_count:
            for line in logs[seen_log_count:]:
                append_log(line)
            seen_log_count = len(logs)

        if manager.is_running:
            summary = format_status_summary(manager.query_status(), manager.mode)
            relay_state_var.set(summary["relay"])
            peer_state_var.set(summary["peer"])
            local_state_var.set(summary["local"])
            relayed_var.set(summary["relayed"])
        elif manager.mode is not None:
            relay_state_var.set("Stopped")
        root.after(500, poll_status)

    def on_close() -> None:
        manager.stop()
        root.destroy()

    root.protocol("WM_DELETE_WINDOW", on_close)
    append_log(f"Game directory: {game_dir if game_dir else 'Not auto-detected'}")
    root.after(250, poll_status)
    root.mainloop()
    return 0


def run_cli(args: argparse.Namespace) -> int:
    """CLI fallback for headless or terminal usage."""
    ts_info = detect_tailscale_ipv4()
    if args.detect_ip:
        print(
            json.dumps(
                {
                    "ip": ts_info.ip,
                    "source": ts_info.source,
                    "detected": ts_info.detected,
                    "share_address": f"{ts_info.ip}:{args.peer_port}",
                }
            )
        )
        return 0

    mode = args.mode
    connect_target = args.connect
    if not mode:
        print(f"Detected Tailscale IPv4: {ts_info.ip} (source: {ts_info.source})")
        print(f"Shareable Host address: {ts_info.ip}:{args.peer_port}")
        choice = input("Select [H]ost, [J]oin, or [Q]uit: ").strip().lower()
        if choice.startswith("h"):
            mode = "host"
        elif choice.startswith("j"):
            mode = "join"
            connect_target = input(f"Enter Host Tailscale IP[:{args.peer_port}]: ").strip()
        else:
            return 0

    manager = RelayProcessManager()
    stop_flag = threading.Event()

    def _handle_sig(_signum: int, _frame: Any) -> None:
        stop_flag.set()

    for sig_name in ("SIGINT", "SIGTERM"):
        sig = getattr(signal, sig_name, None)
        if sig is not None:
            try:
                signal.signal(sig, _handle_sig)
            except (ValueError, OSError):
                pass

    try:
        if mode == "host":
            ctrl_port = manager.start_host(peer_port=args.peer_port, local_port=args.local_port or DEFAULT_HOST_LOCAL_PORT)
            print(f"[launcher] Hosting on {ts_info.ip}:{args.peer_port} (control={ctrl_port})", flush=True)
        elif mode == "join":
            if not connect_target:
                print("[launcher] ERROR: --connect is required for join mode.", file=sys.stderr)
                return 2
            ctrl_port = manager.start_join(
                connect_target, local_port=args.local_port or DEFAULT_CLIENT_LOCAL_PORT
            )
            print(f"[launcher] Joining {connect_target} (control={ctrl_port})", flush=True)
        else:
            print(f"[launcher] ERROR: Unsupported mode '{mode}'.", file=sys.stderr)
            return 2

        if args.launch_steam:
            _, msg = launch_steam_game(find_steam_game_dir())
            print(f"[launcher] {msg}", flush=True)

        last_line = ""
        while not stop_flag.is_set() and manager.is_running:
            summary = format_status_summary(manager.query_status(), manager.mode)
            line = (
                f"relay={summary['relay']} | peer={summary['peer']} | "
                f"local={summary['local']} | relayed={summary['relayed']}"
            )
            if line != last_line:
                print(f"[status] {line}", flush=True)
                last_line = line
            stop_flag.wait(0.75)
    except PortInUseError as exc:
        print(f"[launcher] WARNING: {exc}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        pass
    finally:
        manager.stop()
        print("[launcher] Relay stopped cleanly.", flush=True)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="ss2_coop_launcher.py",
        description="Tailscale Co-op Launcher (Tkinter GUI + CLI fallback) for Swords and Sandals 2.",
    )
    parser.add_argument("--cli", action="store_true", help="Run in terminal CLI mode instead of Tkinter GUI.")
    parser.add_argument("--detect-ip", action="store_true", help="Print detected Tailscale IP JSON and exit (CLI).")
    parser.add_argument("--mode", choices=["host", "join"], default=None, help="Relay mode for --cli.")
    parser.add_argument("--connect", default=None, help="Host Tailscale IP:port for --cli --mode join.")
    parser.add_argument("--peer-port", type=int, default=DEFAULT_PEER_PORT, help=f"Host peer port (default: {DEFAULT_PEER_PORT}).")
    parser.add_argument("--local-port", type=int, default=None, help="Override local XMLSocket port.")
    parser.add_argument("--launch-steam", action="store_true", help="Also launch the Steam game in --cli mode.")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.cli or args.detect_ip:
        return run_cli(args)
    try:
        return launch_gui()
    except Exception as exc:
        print(f"[launcher] GUI unavailable ({exc}); falling back to --cli.", file=sys.stderr)
        return run_cli(args)


if __name__ == "__main__":
    raise SystemExit(main())
