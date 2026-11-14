"""Tests for the Swords and Sandals 2 Co-op Relay (ss2_coop_relay.py)."""

from __future__ import annotations

import asyncio
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
from unittest import mock


PROJECT_ROOT = Path(__file__).resolve().parents[1]
RELAY_DIR = PROJECT_ROOT / "src" / "relay"
RELAY_SCRIPT = RELAY_DIR / "ss2_coop_relay.py"
if str(RELAY_DIR) not in sys.path:
    sys.path.insert(0, str(RELAY_DIR))

import ss2_coop_relay as relay  # noqa: E402


async def read_null_frame(reader: asyncio.StreamReader, timeout: float = 3.0) -> bytes:
    """Read bytes up to the next ``\\x00`` delimiter and return payload without delimiter."""
    buf = bytearray()
    deadline = time.monotonic() + timeout
    while True:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError(f"Timed out waiting for null-terminated frame; buffered={bytes(buf)!r}")
        chunk = await asyncio.wait_for(reader.read(1), timeout=remaining)
        if not chunk:
            raise EOFError(f"EOF before null terminator; buffered={bytes(buf)!r}")
        if chunk == b"\x00":
            return bytes(buf)
        buf.extend(chunk)


async def send_control_cmd(port: int, payload: str | dict[str, object]) -> dict[str, object]:
    """Send one JSON-line command to the relay control TCP port and parse JSON response."""
    reader, writer = await asyncio.open_connection("127.0.0.1", port)
    try:
        line = payload if isinstance(payload, str) else json.dumps(payload)
        writer.write((line + "\n").encode("utf-8"))
        await writer.drain()
        raw = await asyncio.wait_for(reader.readline(), timeout=3.0)
        return json.loads(raw.decode("utf-8"))
    finally:
        writer.close()
        await writer.wait_closed()


class TestHelpers(unittest.TestCase):
    """Unit tests for address parsing and Tailscale IP detection."""

    def test_parse_host_port(self) -> None:
        self.assertEqual(relay.parse_host_port("100.91.119.94:19850"), ("100.91.119.94", 19850))
        self.assertEqual(relay.parse_host_port("127.0.0.1"), ("127.0.0.1", 19850))
        self.assertEqual(relay.parse_host_port("[::1]:20001"), ("::1", 20001))
        self.assertEqual(relay.parse_host_port("tailscale-node:1234"), ("tailscale-node", 1234))

        for bad in ("", ":19850", "127.0.0.1:0", "127.0.0.1:70000", "127.0.0.1:abc", "[::1"):
            with self.assertRaises(ValueError):
                relay.parse_host_port(bad)

    def test_detect_tailscale_ipv4_priority(self) -> None:
        with mock.patch.object(relay, "_detect_via_tailscale_cli", return_value="100.88.10.20"):
            info = relay.detect_tailscale_ipv4()
            self.assertTrue(info.detected)
            self.assertEqual(info.ip, "100.88.10.20")
            self.assertEqual(info.source, "tailscale-cli")

        with (
            mock.patch.object(relay, "_detect_via_tailscale_cli", return_value=None),
            mock.patch.object(relay, "_detect_via_hostname_getaddrinfo", return_value="100.64.12.34"),
        ):
            info = relay.detect_tailscale_ipv4()
            self.assertTrue(info.detected)
            self.assertEqual(info.ip, "100.64.12.34")
            self.assertEqual(info.source, "interface-scan")

        with (
            mock.patch.object(relay, "_detect_via_tailscale_cli", return_value=None),
            mock.patch.object(relay, "_detect_via_hostname_getaddrinfo", return_value=None),
            mock.patch.object(relay, "_detect_via_os_interface_cmd", return_value="100.127.0.5"),
        ):
            info = relay.detect_tailscale_ipv4()
            self.assertTrue(info.detected)
            self.assertEqual(info.ip, "100.127.0.5")
            self.assertEqual(info.source, "os-interface-scan")

        with (
            mock.patch.object(relay, "_detect_via_tailscale_cli", return_value=None),
            mock.patch.object(relay, "_detect_via_hostname_getaddrinfo", return_value=None),
            mock.patch.object(relay, "_detect_via_os_interface_cmd", return_value=None),
        ):
            info = relay.detect_tailscale_ipv4()
            self.assertFalse(info.detected)
            self.assertEqual(info.ip, "127.0.0.1")
            self.assertEqual(info.source, "fallback-localhost")


class TestRelayAsync(unittest.IsolatedAsyncioTestCase):
    """Async integration tests covering host+join, policy requests, partial reads, and local-pair."""

    async def test_host_and_join_bidirectional_over_loopback(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            host_log = Path(tmpdir) / "host_events.jsonl"
            join_log = Path(tmpdir) / "join_events.jsonl"

            host_runner = relay.RelayRunner(
                relay.RelayConfig(
                    mode="host",
                    local_host="127.0.0.1",
                    local_port=0,
                    peer_host="127.0.0.1",
                    peer_port=0,
                    advertise_ip="100.99.88.77",
                    control_port=0,
                    event_log=host_log,
                    quiet=True,
                )
            )
            await host_runner.start()
            host_peer_port = host_runner.bound_ports["peer"]
            host_local_port = host_runner.bound_ports["local"]
            host_ctrl_port = host_runner.bound_ports["control"]

            join_runner = relay.RelayRunner(
                relay.RelayConfig(
                    mode="join",
                    connect_target=f"127.0.0.1:{host_peer_port}",
                    local_host="127.0.0.1",
                    local_port=0,
                    reconnect_delay=0.05,
                    event_log=join_log,
                    quiet=True,
                )
            )
            await join_runner.start()
            join_local_port = join_runner.bound_ports["local"]

            try:
                h_reader, h_writer = await asyncio.open_connection("127.0.0.1", host_local_port)
                j_reader, j_writer = await asyncio.open_connection("127.0.0.1", join_local_port)
                try:
                    msg_from_host = json.dumps({"t": "turn", "hero": "Ümit ⚔️", "dmg": 42}).encode("utf-8")
                    h_writer.write(msg_from_host + b"\x00")
                    await h_writer.drain()

                    received_by_join = await read_null_frame(j_reader)
                    self.assertEqual(received_by_join, msg_from_host)

                    msg_from_join = json.dumps({"t": "ack", "ok": True, "hp": 88}).encode("utf-8")
                    j_writer.write(msg_from_join + b"\x00")
                    await j_writer.drain()

                    received_by_host = await read_null_frame(h_reader)
                    self.assertEqual(received_by_host, msg_from_join)

                    # Verify control status + messages inspection
                    status = await send_control_cmd(host_ctrl_port, "status")
                    self.assertTrue(status["ok"])
                    self.assertEqual(status["mode"], "host")
                    self.assertEqual(status["tailscale_ip"], "100.99.88.77")
                    self.assertEqual(status["stats"]["relayed_count"], 2)

                    messages = await send_control_cmd(host_ctrl_port, "messages")
                    self.assertTrue(messages["ok"])
                    self.assertEqual(len(messages["messages"]), 2)
                finally:
                    h_writer.close()
                    j_writer.close()
                    await asyncio.gather(
                        h_writer.wait_closed(),
                        j_writer.wait_closed(),
                        return_exceptions=True,
                    )
            finally:
                await join_runner.stop()
                await host_runner.stop()

            host_events = [json.loads(line) for line in host_log.read_text(encoding="utf-8").splitlines()]
            relayed = [ev for ev in host_events if ev["event"] == "relayed"]
            self.assertEqual(len(relayed), 2)
            self.assertEqual({ev["direction"] for ev in relayed}, {"local_to_peer", "peer_to_local"})

    async def test_policy_file_request_local_only_and_not_forwarded(self) -> None:
        host_runner = relay.RelayRunner(
            relay.RelayConfig(
                mode="host",
                local_host="127.0.0.1",
                local_port=0,
                peer_host="127.0.0.1",
                peer_port=0,
                quiet=True,
            )
        )
        await host_runner.start()
        join_runner = relay.RelayRunner(
            relay.RelayConfig(
                mode="join",
                connect_target=f"127.0.0.1:{host_runner.bound_ports['peer']}",
                local_host="127.0.0.1",
                local_port=0,
                reconnect_delay=0.05,
                quiet=True,
            )
        )
        await join_runner.start()

        try:
            host_port = host_runner.bound_ports["local"]
            join_port = join_runner.bound_ports["local"]

            # Case 1: Dedicated policy-only socket (Flash connects, gets policy, closes)
            p_reader, p_writer = await asyncio.open_connection("127.0.0.1", host_port)
            p_writer.write(b"<policy-file-request/>\x00")
            await p_writer.drain()
            policy_resp = await read_null_frame(p_reader)
            self.assertEqual(policy_resp + b"\x00", relay.POLICY_RESPONSE)
            p_writer.close()
            await p_writer.wait_closed()

            # Case 2: Policy request on same socket as gameplay, followed by real JSON frame
            h_reader, h_writer = await asyncio.open_connection("127.0.0.1", host_port)
            j_reader, j_writer = await asyncio.open_connection("127.0.0.1", join_port)
            try:
                j_writer.write(b"<policy-file-request/>\x00")
                await j_writer.drain()
                j_policy = await read_null_frame(j_reader)
                self.assertEqual(j_policy + b"\x00", relay.POLICY_RESPONSE)

                # Send real payload from join -> host; host must ONLY see the real payload, never policy XML
                real_payload = b'{"t":"join_hello"}'
                j_writer.write(real_payload + b"\x00")
                await j_writer.drain()
                got = await read_null_frame(h_reader)
                self.assertEqual(got, real_payload)

                # Send real payload from host -> join; join must ONLY see the real payload
                reply_payload = b'{"t":"host_welcome"}'
                h_writer.write(reply_payload + b"\x00")
                await h_writer.drain()
                got_reply = await read_null_frame(j_reader)
                self.assertEqual(got_reply, reply_payload)

                self.assertEqual(host_runner.logger.stats["policy_requests"], 1)
                self.assertEqual(join_runner.logger.stats["policy_requests"], 1)
            finally:
                h_writer.close()
                j_writer.close()
                await asyncio.gather(
                    h_writer.wait_closed(),
                    j_writer.wait_closed(),
                    return_exceptions=True,
                )
        finally:
            await join_runner.stop()
            await host_runner.stop()

    async def test_partial_tcp_reads_and_coalesced_frames(self) -> None:
        pair_runner = relay.RelayRunner(
            relay.RelayConfig(
                mode="local-pair",
                bind_host="127.0.0.1",
                host_port=0,
                client_port=0,
                quiet=True,
            )
        )
        await pair_runner.start()
        try:
            h_reader, h_writer = await asyncio.open_connection(
                "127.0.0.1", pair_runner.bound_ports["host"]
            )
            c_reader, c_writer = await asyncio.open_connection(
                "127.0.0.1", pair_runner.bound_ports["client"]
            )
            try:
                # Drip-feed a policy request 3 bytes at a time
                policy_req = b"<policy-file-request/>\x00"
                for i in range(0, len(policy_req), 3):
                    h_writer.write(policy_req[i : i + 3])
                    await h_writer.drain()
                    await asyncio.sleep(0.004)
                self.assertEqual(await read_null_frame(h_reader) + b"\x00", relay.POLICY_RESPONSE)

                # Send 3 JSON messages across irregular partial chunks + coalesced chunk
                m1 = b'{"seq":1,"act":"slash"}'
                m2 = b'{"seq":2,"act":"block"}'
                m3 = b'{"seq":3,"act":"taunt"}'
                stream = m1 + b"\x00" + m2 + b"\x00" + m3 + b"\x00"
                chunks = [stream[:7], stream[7:25], stream[25:48], stream[48:]]
                for chunk in chunks:
                    h_writer.write(chunk)
                    await h_writer.drain()
                    await asyncio.sleep(0.004)

                self.assertEqual(await read_null_frame(c_reader), m1)
                self.assertEqual(await read_null_frame(c_reader), m2)
                self.assertEqual(await read_null_frame(c_reader), m3)
            finally:
                h_writer.close()
                c_writer.close()
                await asyncio.gather(
                    h_writer.wait_closed(),
                    c_writer.wait_closed(),
                    return_exceptions=True,
                )
        finally:
            await pair_runner.stop()

    async def test_local_pair_with_latency_and_drop_rate(self) -> None:
        # Part A: Latency >= 120ms, strict ordering, policy request remains immediate
        latency_runner = relay.RelayRunner(
            relay.RelayConfig(
                mode="local-pair",
                bind_host="127.0.0.1",
                host_port=0,
                client_port=0,
                latency_ms=120.0,
                drop_rate=0.0,
                quiet=True,
            )
        )
        await latency_runner.start()
        try:
            h_reader, h_writer = await asyncio.open_connection(
                "127.0.0.1", latency_runner.bound_ports["host"]
            )
            c_reader, c_writer = await asyncio.open_connection(
                "127.0.0.1", latency_runner.bound_ports["client"]
            )
            try:
                # Policy request should NOT be delayed by latency_ms
                t_pol = time.monotonic()
                h_writer.write(b"<policy-file-request/>\x00")
                await h_writer.drain()
                self.assertEqual(await read_null_frame(h_reader) + b"\x00", relay.POLICY_RESPONSE)
                self.assertLess(time.monotonic() - t_pol, 0.09)

                # Send burst of 3 ordered frames
                t0 = time.monotonic()
                for seq in (1, 2, 3):
                    h_writer.write(json.dumps({"seq": seq}).encode("utf-8") + b"\x00")
                await h_writer.drain()

                received = [json.loads((await read_null_frame(c_reader)).decode("utf-8")) for _ in range(3)]
                elapsed = time.monotonic() - t0
                self.assertEqual([item["seq"] for item in received], [1, 2, 3])
                self.assertGreaterEqual(elapsed, 0.10)
            finally:
                h_writer.close()
                c_writer.close()
                await asyncio.gather(
                    h_writer.wait_closed(),
                    c_writer.wait_closed(),
                    return_exceptions=True,
                )
        finally:
            await latency_runner.stop()

        # Part B: drop_rate=1.0 drops all game frames
        drop_runner = relay.RelayRunner(
            relay.RelayConfig(
                mode="local-pair",
                bind_host="127.0.0.1",
                host_port=0,
                client_port=0,
                drop_rate=1.0,
                seed=123,
                quiet=True,
            )
        )
        await drop_runner.start()
        try:
            _, h_writer = await asyncio.open_connection("127.0.0.1", drop_runner.bound_ports["host"])
            c_reader, c_writer = await asyncio.open_connection(
                "127.0.0.1", drop_runner.bound_ports["client"]
            )
            try:
                for i in range(5):
                    h_writer.write(f'{{"drop":{i}}}\x00'.encode("utf-8"))
                await h_writer.drain()
                await asyncio.sleep(0.05)
                self.assertEqual(drop_runner.logger.stats["dropped_count"], 5)
                self.assertEqual(drop_runner.logger.stats["relayed_count"], 0)
                with self.assertRaises(asyncio.TimeoutError):
                    await asyncio.wait_for(c_reader.read(1), timeout=0.05)
            finally:
                h_writer.close()
                c_writer.close()
                await asyncio.gather(
                    h_writer.wait_closed(),
                    c_writer.wait_closed(),
                    return_exceptions=True,
                )
        finally:
            await drop_runner.stop()

    async def test_cli_subprocess_local_pair_and_control_shutdown(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            event_log = Path(tmpdir) / "cli_pair.jsonl"
            proc = await asyncio.create_subprocess_exec(
                sys.executable,
                str(RELAY_SCRIPT),
                "local-pair",
                "--bind-host",
                "127.0.0.1",
                "--host-port",
                "0",
                "--client-port",
                "0",
                "--control-port",
                "0",
                "--event-log",
                str(event_log),
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            try:
                assert proc.stdout is not None
                control_port: int | None = None
                host_port: int | None = None
                client_port: int | None = None
                deadline = time.monotonic() + 5.0
                while time.monotonic() < deadline:
                    line_bytes = await asyncio.wait_for(proc.stdout.readline(), timeout=3.0)
                    if not line_bytes:
                        break
                    line = line_bytes.decode("utf-8", errors="replace").strip()
                    if "Host XMLSocket listening on " in line:
                        host_port = int(line.rsplit(":", 1)[1])
                    elif "Client XMLSocket listening on " in line:
                        client_port = int(line.rsplit(":", 1)[1])
                    elif "Control TCP server listening on " in line:
                        control_port = int(line.rsplit(":", 1)[1])
                    if host_port and client_port and control_port:
                        break

                self.assertIsNotNone(host_port)
                self.assertIsNotNone(client_port)
                self.assertIsNotNone(control_port)
                assert host_port and client_port and control_port

                h_reader, h_writer = await asyncio.open_connection("127.0.0.1", host_port)
                c_reader, c_writer = await asyncio.open_connection("127.0.0.1", client_port)
                try:
                    h_writer.write(b'{"t":"ping"}\x00')
                    await h_writer.drain()
                    self.assertEqual(await read_null_frame(c_reader), b'{"t":"ping"}')

                    # Test control inject command -> host receives injected frame
                    inj = await send_control_cmd(
                        control_port,
                        {"cmd": "inject", "target": "host_xml", "payload": '{"t":"injected"}'},
                    )
                    self.assertTrue(inj["ok"])
                    self.assertEqual(await read_null_frame(h_reader), b'{"t":"injected"}')

                    shut = await send_control_cmd(control_port, "shutdown")
                    self.assertTrue(shut["ok"])
                    self.assertTrue(shut["shutting_down"])
                finally:
                    h_writer.close()
                    c_writer.close()
                    await asyncio.gather(
                        h_writer.wait_closed(),
                        c_writer.wait_closed(),
                        return_exceptions=True,
                    )

                rc = await asyncio.wait_for(proc.wait(), timeout=5.0)
                self.assertEqual(rc, 0)
            finally:
                if proc.returncode is None:
                    proc.kill()
                    await proc.wait()

            events = [json.loads(line) for line in event_log.read_text(encoding="utf-8").splitlines()]
            event_types = [ev["event"] for ev in events]
            self.assertIn("started", event_types)
            self.assertIn("relayed", event_types)
            self.assertIn("stopped", event_types)


if __name__ == "__main__":
    unittest.main(verbosity=2)
