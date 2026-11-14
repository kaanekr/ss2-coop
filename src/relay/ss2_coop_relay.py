#!/usr/bin/env python3
"""Zero-dependency Python 3.14 Tailscale + Localhost Co-op Relay for Swords and Sandals 2.

Bridges AS2 XMLSocket (null-byte ``\\x00`` terminated UTF-8 messages) across:
- ``host`` mode: Local Host XMLSocket bridge (default 127.0.0.1:19801) <-> external TCP
  server (default 0.0.0.0:19850), auto-detecting and printing the Tailscale IPv4 address.
- ``join`` mode: Local Client XMLSocket bridge (default 127.0.0.1:19802) <-> remote Host
  peer TCP address (``--connect <host_ip:port>``).
- ``local-pair`` mode: LocalHost 1-PC QA bridge between two XMLSocket ports (defaults
  19801 and 19802) with optional ``--latency-ms`` and ``--drop-rate`` chaos controls.

Handles Flash ``<policy-file-request/>\\x00`` locally on every XMLSocket bridge without
forwarding policy traffic to the peer.
"""

from __future__ import annotations

import argparse
import asyncio
from collections import deque
from dataclasses import dataclass, field
import ipaddress
import json
from pathlib import Path
import random
import re
import shutil
import signal
import socket
import subprocess
import sys
import time
from typing import Any, TextIO


POLICY_REQUEST = b"<policy-file-request/>"
POLICY_RESPONSE = (
    b'<cross-domain-policy><allow-access-from domain="*" to-ports="*"/></cross-domain-policy>\x00'
)

DEFAULT_PEER_PORT = 19850
DEFAULT_HOST_LOCAL_PORT = 19801
DEFAULT_CLIENT_LOCAL_PORT = 19802
DEFAULT_MAX_FRAME_BYTES = 1024 * 1024  # 1 MiB
DEFAULT_HISTORY_SIZE = 200
DEFAULT_RECONNECT_DELAY = 0.5
READ_CHUNK_SIZE = 65536

TAILSCALE_CGNAT = ipaddress.IPv4Network("100.64.0.0/10")
_IPV4_RE = re.compile(r"\b((?:\d{1,3}\.){3}\d{1,3})\b")


@dataclass(frozen=True, slots=True)
class TailscaleInfo:
    """Result of Tailscale IPv4 detection."""

    ip: str
    source: str
    detected: bool


def is_tailscale_ipv4(ip_str: str) -> bool:
    """Return True if ``ip_str`` is a valid IPv4 address in Tailscale's 100.64.0.0/10 range."""
    try:
        addr = ipaddress.IPv4Address(ip_str.strip())
    except ValueError:
        return False
    return addr in TAILSCALE_CGNAT


def _find_tailscale_binaries() -> list[str]:
    candidates: list[str] = []
    which_ts = shutil.which("tailscale")
    if which_ts:
        candidates.append(which_ts)
    for win_path in (
        r"C:\Program Files\Tailscale\tailscale.exe",
        r"C:\Program Files (x86)\Tailscale\tailscale.exe",
    ):
        if Path(win_path).is_file() and win_path not in candidates:
            candidates.append(win_path)
    return candidates


def _detect_via_tailscale_cli() -> str | None:
    for binary in _find_tailscale_binaries():
        try:
            proc = subprocess.run(
                [binary, "ip", "-4"],
                capture_output=True,
                text=True,
                timeout=2.0,
                check=False,
            )
        except (OSError, subprocess.SubprocessError):
            continue
        if proc.returncode != 0:
            continue
        first_valid: str | None = None
        for raw_line in proc.stdout.splitlines():
            line = raw_line.strip()
            if not line:
                continue
            try:
                ipaddress.IPv4Address(line)
            except ValueError:
                continue
            if is_tailscale_ipv4(line):
                return line
            if first_valid is None:
                first_valid = line
        if first_valid is not None:
            return first_valid
    return None


def _detect_via_hostname_getaddrinfo() -> str | None:
    try:
        infos = socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET)
    except OSError:
        return None
    for info in infos:
        ip_str = info[4][0]
        if is_tailscale_ipv4(ip_str):
            return ip_str
    return None


def _detect_via_os_interface_cmd() -> str | None:
    commands: list[list[str]]
    if sys.platform.startswith("win"):
        commands = [["ipconfig"]]
    else:
        commands = [["ip", "-4", "addr"], ["ifconfig"]]

    for cmd in commands:
        if shutil.which(cmd[0]) is None:
            continue
        try:
            proc = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=2.0,
                check=False,
            )
        except (OSError, subprocess.SubprocessError):
            continue
        if proc.returncode != 0:
            continue
        for match in _IPV4_RE.findall(proc.stdout):
            if is_tailscale_ipv4(match):
                return match
    return None


def detect_tailscale_ipv4() -> TailscaleInfo:
    """Detect the local Tailscale IPv4 address via CLI or 100.64.0.0/10 interface scan."""
    cli_ip = _detect_via_tailscale_cli()
    if cli_ip is not None:
        return TailscaleInfo(ip=cli_ip, source="tailscale-cli", detected=True)

    gai_ip = _detect_via_hostname_getaddrinfo()
    if gai_ip is not None:
        return TailscaleInfo(ip=gai_ip, source="interface-scan", detected=True)

    os_ip = _detect_via_os_interface_cmd()
    if os_ip is not None:
        return TailscaleInfo(ip=os_ip, source="os-interface-scan", detected=True)

    return TailscaleInfo(ip="127.0.0.1", source="fallback-localhost", detected=False)


def parse_host_port(value: str, default_port: int = DEFAULT_PEER_PORT) -> tuple[str, int]:
    """Parse ``host:port``, ``[ipv6]:port``, or ``host`` (falling back to ``default_port``)."""
    raw = value.strip()
    if not raw:
        raise ValueError("Host address cannot be empty.")

    if raw.startswith("["):
        end_bracket = raw.find("]")
        if end_bracket == -1:
            raise ValueError(f"Invalid IPv6 host:port '{value}'.")
        host = raw[1:end_bracket].strip()
        rest = raw[end_bracket + 1 :].strip()
        if not rest:
            port = default_port
        elif rest.startswith(":"):
            port_str = rest[1:]
            if not port_str.isdigit():
                raise ValueError(f"Invalid port in '{value}'.")
            port = int(port_str)
        else:
            raise ValueError(f"Invalid host:port '{value}'.")
    elif ":" in raw:
        host, port_str = raw.rsplit(":", 1)
        host = host.strip()
        if not port_str.isdigit():
            raise ValueError(f"Invalid port in '{value}'.")
        port = int(port_str)
    else:
        host = raw
        port = default_port

    if not host:
        raise ValueError(f"Missing host in '{value}'.")
    if not (1 <= port <= 65535):
        raise ValueError(f"Port out of range (1-65535) in '{value}': {port}")
    return host, port


def _tune_socket(writer: asyncio.StreamWriter) -> None:
    sock = writer.get_extra_info("socket")
    if sock is None:
        return
    try:
        sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
    except OSError:
        pass
    try:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
    except OSError:
        pass


def _format_peername(writer: asyncio.StreamWriter) -> str:
    peer = writer.get_extra_info("peername")
    if isinstance(peer, tuple) and len(peer) >= 2:
        return f"{peer[0]}:{peer[1]}"
    return str(peer)


class EventLogger:
    """Tracks relay statistics, recent message history, and optional JSONL file output."""

    def __init__(
        self,
        event_log_path: str | Path | None = None,
        *,
        history_size: int = DEFAULT_HISTORY_SIZE,
        quiet: bool = False,
    ) -> None:
        self.quiet = quiet
        self.started_monotonic = time.monotonic()
        self.history: deque[dict[str, Any]] = deque(maxlen=max(1, history_size))
        self.stats: dict[str, int] = {
            "relayed_count": 0,
            "dropped_count": 0,
            "queue_overflow_count": 0,
            "policy_requests": 0,
            "bytes_relayed": 0,
            "errors": 0,
        }
        self._file: TextIO | None = None
        self.event_log_path = Path(event_log_path) if event_log_path else None
        if self.event_log_path is not None:
            self.event_log_path.parent.mkdir(parents=True, exist_ok=True)
            self._file = self.event_log_path.open("a", encoding="utf-8")

    def log_console(self, message: str, *, force: bool = False) -> None:
        if not self.quiet or force:
            print(f"[ss2-relay] {message}", flush=True)

    def emit(self, event: str, **fields: Any) -> dict[str, Any]:
        record: dict[str, Any] = {
            "ts": round(time.time(), 6),
            "uptime_s": round(time.monotonic() - self.started_monotonic, 6),
            "event": event,
            **fields,
        }
        if event == "relayed":
            self.stats["relayed_count"] += 1
            self.stats["bytes_relayed"] += int(fields.get("bytes", 0))
            self.history.append(record)
        elif event == "dropped":
            self.stats["dropped_count"] += 1
            self.history.append(record)
        elif event == "queue_overflow":
            self.stats["queue_overflow_count"] += 1
        elif event == "policy_request":
            self.stats["policy_requests"] += 1
        elif event == "error":
            self.stats["errors"] += 1

        if self._file is not None:
            self._file.write(json.dumps(record, ensure_ascii=False) + "\n")
            self._file.flush()
        return record

    def close(self) -> None:
        if self._file is not None:
            try:
                self._file.flush()
            finally:
                self._file.close()
                self._file = None


@dataclass(slots=True)
class ConnectionInfo:
    """State for one active TCP stream attached to a RelayEndpoint."""

    conn_id: int
    reader: asyncio.StreamReader
    writer: asyncio.StreamWriter
    addr: str
    connected_at: float = field(default_factory=time.monotonic)
    sent_game_frame: bool = False
    saw_policy: bool = False


class RelayEndpoint:
    """Manages active socket connection(s) for one logical side of the relay."""

    def __init__(
        self,
        name: str,
        *,
        handle_policy: bool,
        single_connection: bool,
        logger: EventLogger,
    ) -> None:
        self.name = name
        self.handle_policy = handle_policy
        self.single_connection = single_connection
        self.logger = logger
        self._next_id = 1
        self._connections: dict[int, ConnectionInfo] = {}
        self._connected_event = asyncio.Event()
        self._write_lock = asyncio.Lock()

    @property
    def is_connected(self) -> bool:
        return bool(self._connections)

    @property
    def connection_count(self) -> int:
        return len(self._connections)

    def snapshot(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "connected": self.is_connected,
            "connection_count": self.connection_count,
            "peers": [c.addr for c in self._connections.values()],
        }

    def register(self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> ConnectionInfo:
        _tune_socket(writer)
        addr = _format_peername(writer)
        if self.single_connection and self._connections:
            for old in list(self._connections.values()):
                self._close_writer_nowait(old)
                self._connections.pop(old.conn_id, None)

        conn = ConnectionInfo(
            conn_id=self._next_id,
            reader=reader,
            writer=writer,
            addr=addr,
        )
        self._next_id += 1
        self._connections[conn.conn_id] = conn
        self._connected_event.set()
        self.logger.emit("connected", side=self.name, addr=addr, conn_id=conn.conn_id)
        return conn

    def unregister(self, conn: ConnectionInfo) -> None:
        removed = self._connections.pop(conn.conn_id, None)
        if removed is not None:
            self._close_writer_nowait(removed)
            self.logger.emit("disconnected", side=self.name, addr=removed.addr, conn_id=removed.conn_id)
        if not self._connections:
            self._connected_event.clear()

    def _close_writer_nowait(self, conn: ConnectionInfo) -> None:
        if not conn.writer.is_closing():
            conn.writer.close()

    async def close_all(self) -> None:
        conns = list(self._connections.values())
        self._connections.clear()
        self._connected_event.clear()
        for conn in conns:
            if not conn.writer.is_closing():
                conn.writer.close()
                try:
                    await conn.writer.wait_closed()
                except (ConnectionError, OSError):
                    pass

    async def wait_connected(self, stop_event: asyncio.Event) -> bool:
        while not self._connections and not stop_event.is_set():
            conn_task = asyncio.create_task(self._connected_event.wait())
            stop_task = asyncio.create_task(stop_event.wait())
            done, pending = await asyncio.wait(
                {conn_task, stop_task},
                return_when=asyncio.FIRST_COMPLETED,
            )
            for task in pending:
                task.cancel()
            if pending:
                await asyncio.gather(*pending, return_exceptions=True)
            for task in done:
                task.exception()
        return not stop_event.is_set()

    def _choose_outbound(self) -> ConnectionInfo | None:
        if not self._connections:
            return None
        conns = list(self._connections.values())
        # Prefer the newest socket that either has sent game traffic or has not been
        # marked policy-only, falling back to the newest socket if all only sent policy.
        for predicate in (
            lambda c: c.sent_game_frame or not c.saw_policy,
            lambda c: True,
        ):
            matching = [c for c in conns if predicate(c)]
            if matching:
                return matching[-1]
        return conns[-1]

    async def send_frame(self, frame: bytes) -> bool:
        """Write ``frame + b'\\x00'`` to the active connection on this endpoint."""
        async with self._write_lock:
            while self._connections:
                conn = self._choose_outbound()
                if conn is None:
                    return False
                try:
                    conn.writer.write(frame + b"\x00")
                    await conn.writer.drain()
                    return True
                except (ConnectionError, OSError) as exc:
                    self.logger.emit(
                        "error",
                        side=self.name,
                        addr=conn.addr,
                        detail=f"write failed: {exc}",
                    )
                    self.unregister(conn)
            return False


class RelayChannel:
    """Unidirectional ordered message pipeline with optional latency and packet drop."""

    def __init__(
        self,
        direction: str,
        target: RelayEndpoint,
        *,
        latency_ms: float,
        drop_rate: float,
        rng: random.Random,
        logger: EventLogger,
        max_queue_size: int = 512,
    ) -> None:
        self.direction = direction
        self.target = target
        self.latency_ms = max(0.0, float(latency_ms))
        self.drop_rate = max(0.0, min(1.0, float(drop_rate)))
        self.rng = rng
        self.logger = logger
        self._queue: asyncio.Queue[tuple[float, int, bytes]] = asyncio.Queue(
            maxsize=max_queue_size
        )
        self._seq = 0

    def enqueue(self, frame: bytes) -> None:
        self._seq += 1
        seq = self._seq
        payload_text = frame.decode("utf-8", errors="replace")

        if self.drop_rate > 0.0 and self.rng.random() < self.drop_rate:
            self.logger.emit(
                "dropped",
                direction=self.direction,
                seq=seq,
                bytes=len(frame),
                payload=payload_text,
            )
            return

        deliver_at = (
            asyncio.get_running_loop().time() + (self.latency_ms / 1000.0)
            if self.latency_ms > 0.0
            else 0.0
        )

        if self._queue.full():
            try:
                self._queue.get_nowait()
                self._queue.task_done()
            except asyncio.QueueEmpty:
                pass
            self.logger.emit("queue_overflow", direction=self.direction, seq=seq)

        self._queue.put_nowait((deliver_at, seq, frame))

    async def run_worker(self, stop_event: asyncio.Event) -> None:
        loop = asyncio.get_running_loop()
        while not stop_event.is_set():
            get_task = asyncio.create_task(self._queue.get())
            stop_task = asyncio.create_task(stop_event.wait())
            done, pending = await asyncio.wait(
                {get_task, stop_task},
                return_when=asyncio.FIRST_COMPLETED,
            )
            for task in pending:
                task.cancel()
            if pending:
                await asyncio.gather(*pending, return_exceptions=True)
            if stop_event.is_set() and get_task not in done:
                break

            deliver_at, seq, frame = get_task.result()
            try:
                if deliver_at > 0.0:
                    remaining = deliver_at - loop.time()
                    if remaining > 0.0:
                        try:
                            await asyncio.wait_for(stop_event.wait(), timeout=remaining)
                            break
                        except asyncio.TimeoutError:
                            pass

                while not stop_event.is_set():
                    if not await self.target.wait_connected(stop_event):
                        return
                    if await self.target.send_frame(frame):
                        self.logger.emit(
                            "relayed",
                            direction=self.direction,
                            seq=seq,
                            bytes=len(frame),
                            payload=frame.decode("utf-8", errors="replace"),
                        )
                        break
            finally:
                self._queue.task_done()


async def _serve_connection(
    endpoint: RelayEndpoint,
    outbound: RelayChannel,
    reader: asyncio.StreamReader,
    writer: asyncio.StreamWriter,
    *,
    max_frame_bytes: int,
) -> None:
    """Read null-terminated frames from ``reader``, handling policy requests locally."""
    conn = endpoint.register(reader, writer)
    buf = bytearray()
    try:
        while True:
            chunk = await reader.read(READ_CHUNK_SIZE)
            if not chunk:
                break
            buf.extend(chunk)

            while True:
                sep = buf.find(b"\x00")
                if sep == -1:
                    break
                frame = bytes(buf[:sep])
                del buf[: sep + 1]

                if frame.strip() == POLICY_REQUEST:
                    conn.saw_policy = True
                    endpoint.logger.emit("policy_request", side=endpoint.name, addr=conn.addr)
                    if endpoint.handle_policy:
                        writer.write(POLICY_RESPONSE)
                        await writer.drain()
                    continue

                conn.sent_game_frame = True
                outbound.enqueue(frame)

            if len(buf) > max_frame_bytes:
                endpoint.logger.emit(
                    "error",
                    side=endpoint.name,
                    addr=conn.addr,
                    detail=f"frame exceeded max_frame_bytes ({max_frame_bytes})",
                )
                break
    except (ConnectionError, OSError) as exc:
        endpoint.logger.emit(
            "error",
            side=endpoint.name,
            addr=conn.addr,
            detail=str(exc),
        )
    except asyncio.CancelledError:
        raise
    finally:
        endpoint.unregister(conn)
        try:
            await writer.wait_closed()
        except (ConnectionError, OSError):
            pass


@dataclass(slots=True)
class RelayConfig:
    """Configuration for ``RelayRunner``."""

    mode: str
    local_host: str = "127.0.0.1"
    local_port: int = DEFAULT_HOST_LOCAL_PORT
    peer_host: str = "0.0.0.0"
    peer_port: int = DEFAULT_PEER_PORT
    connect_target: str | None = None
    advertise_ip: str | None = None
    bind_host: str = "127.0.0.1"
    host_port: int = DEFAULT_HOST_LOCAL_PORT
    client_port: int = DEFAULT_CLIENT_LOCAL_PORT
    reconnect_delay: float = DEFAULT_RECONNECT_DELAY
    latency_ms: float = 0.0
    drop_rate: float = 0.0
    seed: int | None = None
    max_frame_bytes: int = DEFAULT_MAX_FRAME_BYTES
    history_size: int = DEFAULT_HISTORY_SIZE
    event_log: str | Path | None = None
    control_host: str = "127.0.0.1"
    control_port: int | None = None
    quiet: bool = False


class RelayRunner:
    """Async lifecycle manager for host, join, and local-pair relay modes."""

    def __init__(self, config: RelayConfig) -> None:
        if config.mode not in {"host", "join", "local-pair"}:
            raise ValueError(f"Unsupported mode: {config.mode}")
        if not (0.0 <= config.drop_rate <= 1.0):
            raise ValueError(f"--drop-rate must be between 0.0 and 1.0, got {config.drop_rate}")
        if config.latency_ms < 0.0:
            raise ValueError(f"--latency-ms must be >= 0, got {config.latency_ms}")
        if config.max_frame_bytes < 64:
            raise ValueError(f"--max-frame-bytes must be >= 64, got {config.max_frame_bytes}")

        self.config = config
        self.rng = random.Random(config.seed)
        self.logger = EventLogger(
            config.event_log,
            history_size=config.history_size,
            quiet=config.quiet,
        )
        self.stop_event = asyncio.Event()
        self.bound_ports: dict[str, int] = {}
        self.tailscale_info: TailscaleInfo | None = None

        self._servers: list[asyncio.Server] = []
        self._tasks: set[asyncio.Task[Any]] = set()
        self._endpoints: dict[str, RelayEndpoint] = {}
        self._channels: dict[str, RelayChannel] = {}
        self._started = False
        self._stopped = False

    def _spawn(self, coro: Any, *, name: str) -> asyncio.Task[Any]:
        task = asyncio.create_task(coro, name=name)
        self._tasks.add(task)
        task.add_done_callback(self._tasks.discard)
        return task

    @staticmethod
    def _extract_server_port(server: asyncio.Server) -> int:
        assert server.sockets
        return int(server.sockets[0].getsockname()[1])

    async def _start_tcp_server(
        self,
        host: str,
        port: int,
        endpoint: RelayEndpoint,
        outbound: RelayChannel,
        *,
        label: str,
    ) -> asyncio.Server:
        async def on_client(reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
            task = self._spawn(
                _serve_connection(
                    endpoint,
                    outbound,
                    reader,
                    writer,
                    max_frame_bytes=self.config.max_frame_bytes,
                ),
                name=f"conn-{endpoint.name}",
            )
            await task

        server = await asyncio.start_server(on_client, host=host, port=port)
        self._servers.append(server)
        self.bound_ports[label] = self._extract_server_port(server)
        return server

    async def _peer_connector_loop(
        self,
        target_host: str,
        target_port: int,
        peer_ep: RelayEndpoint,
        peer_to_local: RelayChannel,
    ) -> None:
        delay = max(0.05, float(self.config.reconnect_delay))
        while not self.stop_event.is_set():
            try:
                reader, writer = await asyncio.open_connection(target_host, target_port)
            except (ConnectionError, OSError) as exc:
                self.logger.emit(
                    "peer_connect_retry",
                    target=f"{target_host}:{target_port}",
                    detail=str(exc),
                )
                try:
                    await asyncio.wait_for(self.stop_event.wait(), timeout=delay)
                    return
                except asyncio.TimeoutError:
                    continue

            await _serve_connection(
                peer_ep,
                peer_to_local,
                reader,
                writer,
                max_frame_bytes=self.config.max_frame_bytes,
            )
            if self.stop_event.is_set():
                return
            try:
                await asyncio.wait_for(self.stop_event.wait(), timeout=delay)
                return
            except asyncio.TimeoutError:
                pass

    def get_status(self) -> dict[str, Any]:
        return {
            "ok": True,
            "mode": self.config.mode,
            "uptime_s": round(time.monotonic() - self.logger.started_monotonic, 6),
            "ports": dict(self.bound_ports),
            "tailscale_ip": self.tailscale_info.ip if self.tailscale_info else None,
            "tailscale_source": self.tailscale_info.source if self.tailscale_info else None,
            "endpoints": {k: ep.snapshot() for k, ep in self._endpoints.items()},
            "stats": dict(self.logger.stats),
            "latency_ms": self.config.latency_ms,
            "drop_rate": self.config.drop_rate,
        }

    def get_messages(self) -> list[dict[str, Any]]:
        return list(self.logger.history)

    async def _handle_control_client(
        self,
        reader: asyncio.StreamReader,
        writer: asyncio.StreamWriter,
    ) -> None:
        try:
            while not self.stop_event.is_set():
                line = await reader.readline()
                if not line:
                    break
                text = line.decode("utf-8", errors="replace").strip()
                if not text:
                    continue

                if text.startswith("{"):
                    try:
                        req = json.loads(text)
                    except json.JSONDecodeError as exc:
                        resp = {"ok": False, "error": f"invalid json: {exc}"}
                        writer.write((json.dumps(resp) + "\n").encode("utf-8"))
                        await writer.drain()
                        continue
                else:
                    req = {"cmd": text.lower()}

                cmd = str(req.get("cmd", "")).lower()
                if cmd == "status":
                    resp = self.get_status()
                elif cmd == "messages":
                    resp = {"ok": True, "messages": self.get_messages()}
                elif cmd == "ping":
                    resp = {"ok": True, "pong": True}
                elif cmd == "inject":
                    target = str(req.get("target", ""))
                    payload = str(req.get("payload", ""))
                    ep = self._endpoints.get(target)
                    if ep is None:
                        resp = {"ok": False, "error": f"unknown target endpoint '{target}'"}
                    else:
                        sent = await ep.send_frame(payload.encode("utf-8"))
                        resp = {"ok": sent, "target": target}
                elif cmd == "shutdown":
                    resp = {"ok": True, "shutting_down": True}
                    writer.write((json.dumps(resp) + "\n").encode("utf-8"))
                    await writer.drain()
                    self.stop_event.set()
                    break
                else:
                    resp = {"ok": False, "error": f"unknown command '{cmd}'"}

                writer.write((json.dumps(resp, ensure_ascii=False) + "\n").encode("utf-8"))
                await writer.drain()
        except (ConnectionError, OSError):
            pass
        finally:
            if not writer.is_closing():
                writer.close()
                try:
                    await writer.wait_closed()
                except (ConnectionError, OSError):
                    pass

    async def start(self) -> None:
        if self._started:
            return
        self._started = True

        mode = self.config.mode
        if mode == "host":
            local_ep = RelayEndpoint(
                "host_xml", handle_policy=True, single_connection=False, logger=self.logger
            )
            peer_ep = RelayEndpoint(
                "peer", handle_policy=False, single_connection=True, logger=self.logger
            )
            local_to_peer = RelayChannel(
                "local_to_peer",
                peer_ep,
                latency_ms=self.config.latency_ms,
                drop_rate=self.config.drop_rate,
                rng=self.rng,
                logger=self.logger,
            )
            peer_to_local = RelayChannel(
                "peer_to_local",
                local_ep,
                latency_ms=self.config.latency_ms,
                drop_rate=self.config.drop_rate,
                rng=self.rng,
                logger=self.logger,
            )
            self._endpoints = {"host_xml": local_ep, "peer": peer_ep}
            self._channels = {"local_to_peer": local_to_peer, "peer_to_local": peer_to_local}

            await self._start_tcp_server(
                self.config.local_host,
                self.config.local_port,
                local_ep,
                local_to_peer,
                label="local",
            )
            await self._start_tcp_server(
                self.config.peer_host,
                self.config.peer_port,
                peer_ep,
                peer_to_local,
                label="peer",
            )

            if self.config.advertise_ip:
                self.tailscale_info = TailscaleInfo(
                    ip=self.config.advertise_ip, source="cli-override", detected=True
                )
            else:
                self.tailscale_info = detect_tailscale_ipv4()

            share_addr = f"{self.tailscale_info.ip}:{self.bound_ports['peer']}"
            self.logger.log_console(f"Mode: host")
            self.logger.log_console(
                f"Local XMLSocket bridge listening on {self.config.local_host}:{self.bound_ports['local']}"
            )
            self.logger.log_console(
                f"Peer TCP server listening on {self.config.peer_host}:{self.bound_ports['peer']}"
            )
            self.logger.log_console(
                f"Shareable Tailscale IP:port -> {share_addr} (source: {self.tailscale_info.source})",
                force=True,
            )
            if not self.tailscale_info.detected:
                self.logger.log_console(
                    "WARNING: Tailscale IPv4 was not detected; verify Tailscale is connected or pass --advertise-ip.",
                    force=True,
                )
            self.logger.log_console(
                f"Peer join command: python ss2_coop_relay.py join --connect {share_addr}"
            )

        elif mode == "join":
            if not self.config.connect_target:
                raise ValueError("join mode requires --connect <host_ip:port>")
            target_host, target_port = parse_host_port(self.config.connect_target)

            local_ep = RelayEndpoint(
                "client_xml", handle_policy=True, single_connection=False, logger=self.logger
            )
            peer_ep = RelayEndpoint(
                "peer", handle_policy=False, single_connection=True, logger=self.logger
            )
            local_to_peer = RelayChannel(
                "local_to_peer",
                peer_ep,
                latency_ms=self.config.latency_ms,
                drop_rate=self.config.drop_rate,
                rng=self.rng,
                logger=self.logger,
            )
            peer_to_local = RelayChannel(
                "peer_to_local",
                local_ep,
                latency_ms=self.config.latency_ms,
                drop_rate=self.config.drop_rate,
                rng=self.rng,
                logger=self.logger,
            )
            self._endpoints = {"client_xml": local_ep, "peer": peer_ep}
            self._channels = {"local_to_peer": local_to_peer, "peer_to_local": peer_to_local}

            await self._start_tcp_server(
                self.config.local_host,
                self.config.local_port,
                local_ep,
                local_to_peer,
                label="local",
            )
            self._spawn(
                self._peer_connector_loop(target_host, target_port, peer_ep, peer_to_local),
                name="peer-connector",
            )
            self.logger.log_console("Mode: join")
            self.logger.log_console(
                f"Local XMLSocket bridge listening on {self.config.local_host}:{self.bound_ports['local']}"
            )
            self.logger.log_console(f"Connecting to host peer at {target_host}:{target_port}")

        elif mode == "local-pair":
            host_ep = RelayEndpoint(
                "host_xml", handle_policy=True, single_connection=False, logger=self.logger
            )
            client_ep = RelayEndpoint(
                "client_xml", handle_policy=True, single_connection=False, logger=self.logger
            )
            host_to_client = RelayChannel(
                "host_to_client",
                client_ep,
                latency_ms=self.config.latency_ms,
                drop_rate=self.config.drop_rate,
                rng=self.rng,
                logger=self.logger,
            )
            client_to_host = RelayChannel(
                "client_to_host",
                host_ep,
                latency_ms=self.config.latency_ms,
                drop_rate=self.config.drop_rate,
                rng=self.rng,
                logger=self.logger,
            )
            self._endpoints = {"host_xml": host_ep, "client_xml": client_ep}
            self._channels = {
                "host_to_client": host_to_client,
                "client_to_host": client_to_host,
            }

            await self._start_tcp_server(
                self.config.bind_host,
                self.config.host_port,
                host_ep,
                host_to_client,
                label="host",
            )
            await self._start_tcp_server(
                self.config.bind_host,
                self.config.client_port,
                client_ep,
                client_to_host,
                label="client",
            )
            self.logger.log_console(
                f"Mode: local-pair (latency_ms={self.config.latency_ms}, drop_rate={self.config.drop_rate})"
            )
            self.logger.log_console(
                f"Host XMLSocket listening on {self.config.bind_host}:{self.bound_ports['host']}"
            )
            self.logger.log_console(
                f"Client XMLSocket listening on {self.config.bind_host}:{self.bound_ports['client']}"
            )

        for cname, channel in self._channels.items():
            self._spawn(channel.run_worker(self.stop_event), name=f"worker-{cname}")

        if self.config.control_port is not None:
            ctrl_server = await asyncio.start_server(
                self._handle_control_client,
                host=self.config.control_host,
                port=self.config.control_port,
            )
            self._servers.append(ctrl_server)
            self.bound_ports["control"] = self._extract_server_port(ctrl_server)
            self.logger.log_console(
                f"Control TCP server listening on {self.config.control_host}:{self.bound_ports['control']}"
            )

        self.logger.emit(
            "started",
            mode=mode,
            ports=dict(self.bound_ports),
            tailscale_ip=self.tailscale_info.ip if self.tailscale_info else None,
            latency_ms=self.config.latency_ms,
            drop_rate=self.config.drop_rate,
        )

    async def run_until_stopped(self) -> None:
        try:
            await self.start()
            await self.stop_event.wait()
        finally:
            await self.stop()

    async def stop(self) -> None:
        if self._stopped:
            return
        self._stopped = True
        self.stop_event.set()

        for server in self._servers:
            server.close()
        for server in self._servers:
            try:
                await server.wait_closed()
            except (ConnectionError, OSError):
                pass
        self._servers.clear()

        for ep in self._endpoints.values():
            await ep.close_all()

        pending_tasks = list(self._tasks)
        for task in pending_tasks:
            task.cancel()
        if pending_tasks:
            await asyncio.gather(*pending_tasks, return_exceptions=True)
        self._tasks.clear()

        self.logger.emit("stopped", stats=dict(self.logger.stats))
        self.logger.close()


def build_arg_parser() -> argparse.ArgumentParser:
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument(
        "--latency-ms",
        type=float,
        default=0.0,
        help="Simulated one-way relay latency in milliseconds (default: 0).",
    )
    common.add_argument(
        "--drop-rate",
        type=float,
        default=0.0,
        help="Simulated packet drop probability 0.0..1.0 (default: 0).",
    )
    common.add_argument(
        "--seed",
        type=int,
        default=None,
        help="Optional PRNG seed for reproducible --drop-rate tests.",
    )
    common.add_argument(
        "--event-log",
        type=str,
        default=None,
        help="Path to append JSONL relay events for QA inspection.",
    )
    common.add_argument(
        "--control-port",
        type=int,
        default=None,
        help="Optional localhost TCP JSON-lines status/control port (0 = ephemeral).",
    )
    common.add_argument(
        "--control-host",
        type=str,
        default="127.0.0.1",
        help="Bind host for --control-port (default: 127.0.0.1).",
    )
    common.add_argument(
        "--max-frame-bytes",
        type=int,
        default=DEFAULT_MAX_FRAME_BYTES,
        help=f"Max bytes allowed before a null terminator (default: {DEFAULT_MAX_FRAME_BYTES}).",
    )
    common.add_argument(
        "--history-size",
        type=int,
        default=DEFAULT_HISTORY_SIZE,
        help=f"Recent messages retained in memory for control queries (default: {DEFAULT_HISTORY_SIZE}).",
    )
    common.add_argument(
        "-q",
        "--quiet",
        action="store_true",
        help="Suppress non-essential stdout banner lines.",
    )

    parser = argparse.ArgumentParser(
        prog="ss2_coop_relay.py",
        description="Zero-dependency Tailscale + Localhost Co-op Relay for Swords and Sandals 2 (AS2 XMLSocket).",
    )
    sub = parser.add_subparsers(dest="mode", required=True)

    p_host = sub.add_parser("host", parents=[common], help="Run as Co-op Host relay.")
    p_host.add_argument("--peer-host", default="0.0.0.0", help="External peer TCP bind host (default: 0.0.0.0).")
    p_host.add_argument("--peer-port", type=int, default=DEFAULT_PEER_PORT, help=f"External peer TCP port (default: {DEFAULT_PEER_PORT}).")
    p_host.add_argument("--local-host", default="127.0.0.1", help="Local XMLSocket bind host (default: 127.0.0.1).")
    p_host.add_argument("--local-port", type=int, default=DEFAULT_HOST_LOCAL_PORT, help=f"Local XMLSocket port for Host game (default: {DEFAULT_HOST_LOCAL_PORT}).")
    p_host.add_argument("--advertise-ip", default=None, help="Override detected Tailscale IPv4 in printed share address.")

    p_join = sub.add_parser("join", parents=[common], help="Run as Co-op Client relay connecting to a Host.")
    p_join.add_argument("--connect", required=True, dest="connect_target", help="Host peer address <host_ip:port>.")
    p_join.add_argument("--local-host", default="127.0.0.1", help="Local XMLSocket bind host (default: 127.0.0.1).")
    p_join.add_argument("--local-port", type=int, default=DEFAULT_CLIENT_LOCAL_PORT, help=f"Local XMLSocket port for Client game (default: {DEFAULT_CLIENT_LOCAL_PORT}).")
    p_join.add_argument("--reconnect-delay", type=float, default=DEFAULT_RECONNECT_DELAY, help=f"Seconds between peer reconnect attempts (default: {DEFAULT_RECONNECT_DELAY}).")

    p_pair = sub.add_parser("local-pair", parents=[common], help="Run 1-PC QA bridge linking two local XMLSocket ports.")
    p_pair.add_argument("--bind-host", default="127.0.0.1", help="Local bind host for both XMLSocket ports (default: 127.0.0.1).")
    p_pair.add_argument("--host-port", type=int, default=DEFAULT_HOST_LOCAL_PORT, help=f"Host game XMLSocket port (default: {DEFAULT_HOST_LOCAL_PORT}).")
    p_pair.add_argument("--client-port", type=int, default=DEFAULT_CLIENT_LOCAL_PORT, help=f"Client game XMLSocket port (default: {DEFAULT_CLIENT_LOCAL_PORT}).")

    return parser


def config_from_args(ns: argparse.Namespace) -> RelayConfig:
    return RelayConfig(
        mode=ns.mode,
        local_host=getattr(ns, "local_host", "127.0.0.1"),
        local_port=getattr(ns, "local_port", DEFAULT_HOST_LOCAL_PORT),
        peer_host=getattr(ns, "peer_host", "0.0.0.0"),
        peer_port=getattr(ns, "peer_port", DEFAULT_PEER_PORT),
        connect_target=getattr(ns, "connect_target", None),
        advertise_ip=getattr(ns, "advertise_ip", None),
        bind_host=getattr(ns, "bind_host", "127.0.0.1"),
        host_port=getattr(ns, "host_port", DEFAULT_HOST_LOCAL_PORT),
        client_port=getattr(ns, "client_port", DEFAULT_CLIENT_LOCAL_PORT),
        reconnect_delay=getattr(ns, "reconnect_delay", DEFAULT_RECONNECT_DELAY),
        latency_ms=ns.latency_ms,
        drop_rate=ns.drop_rate,
        seed=ns.seed,
        max_frame_bytes=ns.max_frame_bytes,
        history_size=ns.history_size,
        event_log=ns.event_log,
        control_host=ns.control_host,
        control_port=ns.control_port,
        quiet=ns.quiet,
    )


async def _run_cli(config: RelayConfig) -> None:
    runner = RelayRunner(config)
    loop = asyncio.get_running_loop()

    def _on_signal(_signum: int, _frame: Any) -> None:
        loop.call_soon_threadsafe(runner.stop_event.set)

    for sig_name in ("SIGTERM", "SIGINT"):
        sig = getattr(signal, sig_name, None)
        if sig is not None:
            try:
                signal.signal(sig, _on_signal)
            except (ValueError, OSError):
                pass

    await runner.run_until_stopped()


def main(argv: list[str] | None = None) -> int:
    parser = build_arg_parser()
    ns = parser.parse_args(argv)
    try:
        config = config_from_args(ns)
        asyncio.run(_run_cli(config))
    except KeyboardInterrupt:
        return 0
    except (ValueError, OSError) as exc:
        print(f"[ss2-relay] ERROR: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
