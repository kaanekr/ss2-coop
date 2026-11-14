"""Tests for install_coop.ps1, install_coop.bat, uninstall_coop.ps1, and ss2_coop_launcher.py."""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import unittest


PROJECT_ROOT = Path(__file__).resolve().parents[1]
LAUNCHER_DIR = PROJECT_ROOT / "src" / "launcher"
if str(LAUNCHER_DIR) not in sys.path:
    sys.path.insert(0, str(LAUNCHER_DIR))

import ss2_coop_launcher as launcher  # noqa: E402

STOCK_SWF_SHA256 = "77CB545C2061AB41246251467A4EDF5926AB6FD1DDD95DC9527D7BA9C45BB8CA"
STOCK_TEST_SWF = PROJECT_ROOT / "local" / "test_env" / "host" / "swf" / "swords_sandals2_download.swf"
DIST_COOP_SWF = PROJECT_ROOT / "dist" / "swords_sandals2_coop.swf"
INSTALL_PS1 = PROJECT_ROOT / "install_coop.ps1"
INSTALL_BAT = PROJECT_ROOT / "install_coop.bat"
UNINSTALL_PS1 = PROJECT_ROOT / "uninstall_coop.ps1"


def sha256_upper(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        while chunk := fh.read(65536):
            h.update(chunk)
    return h.hexdigest().upper()


def free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", 0))
        return int(s.getsockname()[1])


class TestInstallerSandbox(unittest.TestCase):
    """End-to-end installer/uninstaller tests against a temporary game directory."""

    def run_installer(self, args: list[str]) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            args,
            capture_output=True,
            text=True,
            check=False,
            env=self.installer_env,
            timeout=30,
        )

    def setUp(self) -> None:
        self.assertTrue(STOCK_TEST_SWF.is_file(), f"Missing stock test SWF: {STOCK_TEST_SWF}")
        self.assertTrue(DIST_COOP_SWF.is_file(), f"Missing built coop SWF: {DIST_COOP_SWF}")
        self.assertEqual(sha256_upper(STOCK_TEST_SWF), STOCK_SWF_SHA256)

        temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(temp_dir.cleanup)
        workspace = Path(temp_dir.name)
        self.game_dir = workspace / "game"
        self.manifest = workspace / "manifest.json"
        swf_dir = self.game_dir / "swf"
        swf_dir.mkdir(parents=True)
        self.sandbox_swf = swf_dir / "swords_sandals2_download.swf"
        self.sandbox_bak = swf_dir / "swords_sandals2_download.swf.bak"
        self.sandbox_marker = swf_dir / "ss2_coop_install.json"
        shutil.copy2(STOCK_TEST_SWF, self.sandbox_swf)

        # Windows PowerShell must resolve its own modules when launched from pwsh.
        self.installer_env = os.environ.copy()
        self.installer_env["PSModulePath"] = str(
            Path(os.environ["SystemRoot"]) / "System32" / "WindowsPowerShell" / "v1.0" / "Modules"
        )
        res = self.run_installer(
            [
                "powershell.exe",
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(INSTALL_PS1),
                "-GenerateManifest",
                "-ManifestPath",
                str(self.manifest),
            ],
        )
        self.assertEqual(res.returncode, 0, res.stdout + "\n" + res.stderr)
        self.coop_hash = sha256_upper(DIST_COOP_SWF)

    def test_install_idempotent_update_and_uninstall_roundtrip(self) -> None:
        # 1. Fresh install via install_coop.ps1
        res_install = self.run_installer(
            [
                "powershell.exe",
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(INSTALL_PS1),
                "-GameDir",
                str(self.game_dir),
                "-ManifestPath",
                str(self.manifest),
            ],
        )
        self.assertEqual(res_install.returncode, 0, res_install.stdout + "\n" + res_install.stderr)
        self.assertTrue(self.sandbox_bak.is_file())
        self.assertTrue(self.sandbox_marker.is_file())
        self.assertEqual(sha256_upper(self.sandbox_bak), STOCK_SWF_SHA256)
        self.assertEqual(sha256_upper(self.sandbox_swf), self.coop_hash)

        # 2. Idempotent re-run / update via install_coop.bat
        res_update = self.run_installer(
            [
                "cmd.exe", "/c", str(INSTALL_BAT),
                "-GameDir", str(self.game_dir),
                "-ManifestPath", str(self.manifest),
            ],
        )
        self.assertEqual(res_update.returncode, 0, res_update.stdout + "\n" + res_update.stderr)
        self.assertEqual(sha256_upper(self.sandbox_bak), STOCK_SWF_SHA256)
        self.assertEqual(sha256_upper(self.sandbox_swf), self.coop_hash)

        # 3. Uninstall via uninstall_coop.ps1
        res_uninstall = self.run_installer(
            [
                "powershell.exe",
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(UNINSTALL_PS1),
                "-GameDir",
                str(self.game_dir),
                "-SkipAppDataCfg",
            ],
        )
        self.assertEqual(res_uninstall.returncode, 0, res_uninstall.stdout + "\n" + res_uninstall.stderr)
        self.assertFalse(self.sandbox_bak.exists())
        self.assertFalse(self.sandbox_marker.exists())
        self.assertEqual(sha256_upper(self.sandbox_swf), STOCK_SWF_SHA256)

        # 4. Idempotent second uninstall
        res_uninstall_again = self.run_installer(
            [
                "powershell.exe",
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(UNINSTALL_PS1),
                "-GameDir",
                str(self.game_dir),
                "-SkipAppDataCfg",
            ],
        )
        self.assertEqual(
            res_uninstall_again.returncode,
            0,
            res_uninstall_again.stdout + "\n" + res_uninstall_again.stderr,
        )
        self.assertEqual(sha256_upper(self.sandbox_swf), STOCK_SWF_SHA256)

    def test_install_rejects_tampered_stock_and_tampered_manifest(self) -> None:
        # Case A: Tampered stock SWF must abort without creating .bak or replacing target
        self.sandbox_swf.write_bytes(b"NOT_THE_STOCK_SWF")
        bad_stock_hash = sha256_upper(self.sandbox_swf)
        res_bad_stock = self.run_installer(
            [
                "powershell.exe",
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(INSTALL_PS1),
                "-GameDir",
                str(self.game_dir),
                "-ManifestPath",
                str(self.manifest),
            ],
        )
        self.assertNotEqual(res_bad_stock.returncode, 0)
        self.assertFalse(self.sandbox_bak.exists())
        self.assertEqual(sha256_upper(self.sandbox_swf), bad_stock_hash)

        # Restore stock SWF and test Case B: tampered manifest hash must abort
        shutil.copy2(STOCK_TEST_SWF, self.sandbox_swf)
        with tempfile.TemporaryDirectory() as tmpdir:
            bad_manifest = Path(tmpdir) / "bad_manifest.json"
            manifest_data = json.loads(self.manifest.read_text(encoding="utf-8"))
            manifest_data["coop_swf_sha256"] = "0" * 64
            bad_manifest.write_text(json.dumps(manifest_data), encoding="utf-8")

            res_bad_manifest = self.run_installer(
                [
                    "powershell.exe",
                    "-NoProfile",
                    "-ExecutionPolicy",
                    "Bypass",
                    "-File",
                    str(INSTALL_PS1),
                    "-GameDir",
                    str(self.game_dir),
                    "-ManifestPath",
                    str(bad_manifest),
                ],
            )
            self.assertNotEqual(res_bad_manifest.returncode, 0)
            self.assertFalse(self.sandbox_bak.exists())
            self.assertEqual(sha256_upper(self.sandbox_swf), STOCK_SWF_SHA256)


class TestLauncher(unittest.TestCase):
    """Tests for ss2_coop_launcher.py CLI detection and managed relay lifecycle."""

    def test_cli_detect_ip(self) -> None:
        launcher_script = PROJECT_ROOT / "src" / "launcher" / "ss2_coop_launcher.py"
        res = subprocess.run(
            [sys.executable, str(launcher_script), "--cli", "--detect-ip"],
            capture_output=True,
            text=True,
            check=False,
            timeout=10,
        )
        self.assertEqual(res.returncode, 0, res.stderr)
        data = json.loads(res.stdout.strip())
        self.assertIn("ip", data)
        self.assertIn("share_address", data)
        self.assertIn("detected", data)

    def test_relay_process_manager_host_and_join(self) -> None:
        host_mgr = launcher.RelayProcessManager()
        join_mgr = launcher.RelayProcessManager()
        peer_port = free_port()
        host_local_port = free_port()
        join_local_port = free_port()
        try:
            host_ctrl = host_mgr.start_host(
                peer_host="127.0.0.1",
                peer_port=peer_port,
                local_host="127.0.0.1",
                local_port=host_local_port,
                advertise_ip="100.64.1.2",
            )
            self.assertGreater(host_ctrl, 0)
            self.assertTrue(host_mgr.is_running)

            join_ctrl = join_mgr.start_join(
                f"127.0.0.1:{peer_port}",
                local_host="127.0.0.1",
                local_port=join_local_port,
            )
            self.assertGreater(join_ctrl, 0)
            self.assertTrue(join_mgr.is_running)

            # Wait briefly for peer connection to establish
            connected = False
            deadline = time.monotonic() + 4.0
            while time.monotonic() < deadline:
                st = host_mgr.query_status()
                if st and st.get("endpoints", {}).get("peer", {}).get("connected"):
                    connected = True
                    summary = launcher.format_status_summary(st, "host")
                    self.assertIn("Connected", summary["peer"])
                    break
                time.sleep(0.05)
            self.assertTrue(connected, "Join relay did not connect to Host relay in time.")
        finally:
            join_mgr.stop()
            host_mgr.stop()
            self.assertFalse(join_mgr.is_running)
            self.assertFalse(host_mgr.is_running)

    def test_port_in_use_raises_friendly_error_without_traceback(self) -> None:
        host_mgr1 = launcher.RelayProcessManager()
        host_mgr2 = launcher.RelayProcessManager()
        peer_port = free_port()
        local_port = free_port()
        try:
            host_mgr1.start_host(
                peer_host="127.0.0.1",
                peer_port=peer_port,
                local_host="127.0.0.1",
                local_port=local_port,
                advertise_ip="100.64.1.2",
            )
            self.assertTrue(launcher.is_tcp_port_listening("127.0.0.1", local_port))
            self.assertTrue(launcher.is_tcp_port_listening("0.0.0.0", peer_port))

            with self.assertRaises(launcher.PortInUseError) as ctx:
                host_mgr2.start_host(
                    peer_host="127.0.0.1",
                    peer_port=peer_port,
                    local_host="127.0.0.1",
                    local_port=local_port,
                )
            msg = str(ctx.exception)
            self.assertIn(str(local_port), msg)
            self.assertNotIn("Traceback", msg)
            self.assertTrue(host_mgr1.is_running)

            # Verify CLI launcher also exits cleanly without raw traceback
            launcher_script = PROJECT_ROOT / "src" / "launcher" / "ss2_coop_launcher.py"
            res = subprocess.run(
                [
                    sys.executable,
                    str(launcher_script),
                    "--cli",
                    "--mode",
                    "host",
                    "--peer-port",
                    str(peer_port),
                    "--local-port",
                    str(local_port),
                ],
                capture_output=True,
                text=True,
                check=False,
                timeout=10,
            )
            self.assertEqual(res.returncode, 1)
            self.assertNotIn("Traceback", res.stderr)
            self.assertIn(str(local_port), res.stderr)
        finally:
            host_mgr2.stop()
            host_mgr1.stop()


if __name__ == "__main__":
    unittest.main(verbosity=2)
