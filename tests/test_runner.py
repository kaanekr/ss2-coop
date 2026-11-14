"""QA tests for the independent Ruffle SWF runner and AS2 XMLSocket support."""

from __future__ import annotations

from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import threading
import time
import unittest

PROJECT_ROOT = Path(__file__).resolve().parents[1]
RUNNER_DIR = PROJECT_ROOT / "tools" / "runner"
FFDEC_JAR = PROJECT_ROOT / "tools" / "ffdec" / "ffdec.jar"
SS2_SWF = Path(
    r"C:\Program Files (x86)\Steam\steamapps\common\Swords and Sandals Classic Collection\swf\swords_sandals2_download.swf"
)

if str(RUNNER_DIR) not in sys.path:
    sys.path.insert(0, str(RUNNER_DIR))

import runner  # noqa: E402

PATCHED_FRAME1_AS = """this._lockroot = true;
_root.fizMode = "fizzle";
var __sock = new XMLSocket();
_global.__testSock = __sock;
__sock.onConnect = function(success)
{
   if(success)
   {
      this.send("HELLO_SS2");
   }
};
__sock.onData = function(data)
{
   if(data == "PING_FROM_SERVER")
   {
      this.send("PONG_SS2");
   }
};
__sock.connect("127.0.0.1",__PORT__);
gotoAndStop("splash");
_global.debugMode = false;
"""


class DummyXmlSocketServer:
    """Minimal multi-client null-byte XMLSocket listener for QA tests."""

    def __init__(self, host: str = "127.0.0.1", port: int = 19809) -> None:
        self.host = host
        self.port = port
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sock.bind((host, port))
        self.sock.listen(8)
        self.sock.settimeout(0.2)
        self.port = self.sock.getsockname()[1]

        self._stop = threading.Event()
        self._lock = threading.Lock()
        self.messages: list[bytes] = []
        self.hello_count = 0
        self.pong_count = 0
        self.policy_requests = 0
        self._done_event = threading.Event()
        self._target_count = 1
        self._threads: list[threading.Thread] = []
        self._accept_thread = threading.Thread(target=self._accept_loop, daemon=True)

    def start(self, expected_clients: int = 1) -> None:
        self._target_count = expected_clients
        self._accept_thread.start()

    def wait_for_handshakes(self, timeout: float = 12.0) -> bool:
        return self._done_event.wait(timeout=timeout)

    def _accept_loop(self) -> None:
        while not self._stop.is_set():
            try:
                conn, _ = self.sock.accept()
            except socket.timeout:
                continue
            except OSError:
                break
            t = threading.Thread(target=self._handle_client, args=(conn,), daemon=True)
            self._threads.append(t)
            t.start()

    def _handle_client(self, conn: socket.socket) -> None:
        conn.settimeout(0.2)
        buf = b""
        try:
            while not self._stop.is_set():
                try:
                    chunk = conn.recv(4096)
                except socket.timeout:
                    continue
                except OSError:
                    break
                if not chunk:
                    break
                buf += chunk
                while b"\x00" in buf:
                    msg, buf = buf.split(b"\x00", 1)
                    with self._lock:
                        self.messages.append(msg)
                    if msg == b"<policy-file-request/>":
                        with self._lock:
                            self.policy_requests += 1
                        conn.sendall(
                            b'<cross-domain-policy><allow-access-from domain="*" to-ports="*"/></cross-domain-policy>\x00'
                        )
                    elif msg == b"HELLO_SS2":
                        with self._lock:
                            self.hello_count += 1
                        conn.sendall(b"PING_FROM_SERVER\x00")
                    elif msg == b"PONG_SS2":
                        with self._lock:
                            self.pong_count += 1
                            if (
                                self.hello_count >= self._target_count
                                and self.pong_count >= self._target_count
                            ):
                                self._done_event.set()
        finally:
            conn.close()

    def close(self) -> None:
        self._stop.set()
        try:
            self.sock.close()
        except OSError:
            pass
        self._accept_thread.join(timeout=2.0)
        for t in self._threads:
            t.join(timeout=1.0)


def build_temp_patched_swf(tmp_dir: Path, port: int) -> Path:
    """Create a temporary SS2 SWF with an XMLSocket probe on frame 1."""
    scripts_root = tmp_dir / "patch_scripts"
    frame1 = scripts_root / "scripts" / "frame_1"
    frame1.mkdir(parents=True, exist_ok=True)
    (frame1 / "DoAction.as").write_text(
        PATCHED_FRAME1_AS.replace("__PORT__", str(port)),
        encoding="utf-8",
    )
    out_swf = tmp_dir / "ss2_socket_probe.swf"
    proc = subprocess.run(
        [
            "java",
            "-jar",
            str(FFDEC_JAR),
            "-importScript",
            str(SS2_SWF),
            str(out_swf),
            str(scripts_root),
        ],
        capture_output=True,
        text=True,
        timeout=30,
        check=False,
    )
    if proc.returncode != 0 or not out_swf.is_file():
        raise RuntimeError(
            f"ffdec -importScript failed ({proc.returncode}): {proc.stdout}\n{proc.stderr}"
        )
    return out_swf


class TestSwfRunner(unittest.TestCase):
    def test_runner_binary_present(self) -> None:
        self.assertTrue(runner.RUFFLE_EXE.is_file(), f"Missing {runner.RUFFLE_EXE}")
        self.assertTrue(SS2_SWF.is_file(), f"Missing {SS2_SWF}")
        self.assertTrue(FFDEC_JAR.is_file(), f"Missing {FFDEC_JAR}")
        res = subprocess.run(
            [str(runner.RUFFLE_EXE), "--version"],
            capture_output=True,
            text=True,
            timeout=10,
            check=True,
        )
        self.assertIn("Ruffle", res.stdout)

    def test_two_simultaneous_windows(self) -> None:
        procs = [
            runner.launch_client(SS2_SWF, width=640, height=480, volume=0.0)
            for _ in range(2)
        ]
        try:
            windows = runner.wait_for_windows(procs, timeout=12.0)
            self.assertEqual(len(windows), 2)
            for idx, proc in enumerate(procs):
                titles = [title for _, title in windows[proc.pid] if title.strip()]
                self.assertTrue(titles, f"No titled window found for PID {proc.pid}")
                self.assertIn("Ruffle", titles[0])
                hwnd = next(h for h, title in windows[proc.pid] if title.strip())
                runner.position_window(hwnd, 40 + idx * 660, 60)

            time.sleep(2.0)
            for proc in procs:
                self.assertIsNone(proc.poll(), f"Process {proc.pid} exited unexpectedly")
        finally:
            runner.terminate_processes(procs)

    def test_xmlsocket_handshake_two_windows(self) -> None:
        server = DummyXmlSocketServer("127.0.0.1", 19809)
        server.start(expected_clients=2)
        procs: list[subprocess.Popen[bytes]] = []
        try:
            with tempfile.TemporaryDirectory() as td:
                patched_swf = build_temp_patched_swf(Path(td), server.port)
                procs = [
                    runner.launch_client(
                        patched_swf,
                        width=640,
                        height=480,
                        volume=0.0,
                        socket_allow=[f"127.0.0.1:{server.port}"],
                    )
                    for _ in range(2)
                ]
                windows = runner.wait_for_windows(procs, timeout=12.0)
                self.assertEqual(len(windows), 2)
                ok = server.wait_for_handshakes(timeout=12.0)
                self.assertTrue(
                    ok,
                    f"Timed out waiting for 2 XMLSocket handshakes; "
                    f"hello={server.hello_count}, pong={server.pong_count}, msgs={server.messages}",
                )
                self.assertGreaterEqual(server.hello_count, 2)
                self.assertGreaterEqual(server.pong_count, 2)
        finally:
            runner.terminate_processes(procs)
            server.close()

    def test_xmlsocket_denied_when_tcp_deny(self) -> None:
        server = DummyXmlSocketServer("127.0.0.1", 19809)
        server.start(expected_clients=1)
        procs: list[subprocess.Popen[bytes]] = []
        try:
            with tempfile.TemporaryDirectory() as td:
                patched_swf = build_temp_patched_swf(Path(td), server.port)
                procs = [
                    runner.launch_client(
                        patched_swf,
                        width=640,
                        height=480,
                        volume=0.0,
                        tcp_connections="deny",
                    )
                ]
                runner.wait_for_windows(procs, timeout=10.0)
                self.assertFalse(server.wait_for_handshakes(timeout=2.0))
                self.assertEqual(server.hello_count, 0)
        finally:
            runner.terminate_processes(procs)
            server.close()


if __name__ == "__main__":
    unittest.main(verbosity=2)
