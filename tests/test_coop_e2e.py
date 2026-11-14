"""Automated end-to-end Co-op QA tests using ss2_coop_relay.py local-pair + 2 Ruffle windows."""

from __future__ import annotations

import argparse
from collections.abc import Callable
import json
from pathlib import Path
import sys
import time
import unittest

PROJECT_ROOT = Path(__file__).resolve().parents[1]
RUNNER_DIR = PROJECT_ROOT / "tools" / "runner"

if str(RUNNER_DIR) not in sys.path:
    sys.path.insert(0, str(RUNNER_DIR))

from local_qa import COOP_SWF, control_request, launch_pair  # noqa: E402


def parse_coop_payload(payload: str) -> dict[str, str]:
    """Parse a `COOP|t=...|k=v|...` message string into a dict."""
    if not payload.startswith("COOP|"):
        return {}
    out: dict[str, str] = {}
    for seg in payload.split("|")[1:]:
        if "=" in seg:
            k, v = seg.split("=", 1)
            out[k] = v
    return out


SYNC_PARITY_KEYS = ("h1x", "h2x", "vx", "h1hp", "h2hp", "vhp", "h1arm", "h2arm", "varm", "turn")
MOVEMENT_ACTIONS = {"jumpright", "jumpleft", "walkright", "walkleft", "chargeright", "chargeleft"}
ATTACK_ACTIONS = {"normal_attack", "power_attack", "quick_attack", "fire_arrow", "bash"}
STANDING_FRAMES = range(1, 33)
TAUNT_REACTIONS = {
    "block": range(572, 585),     # Defend20
    "hit": range(1362, 1380),    # Hurt20
    "knockback": range(1428, 1447),
}


class _RuffleWgpuRetryError(RuntimeError):
    """Raised when Ruffle exits early on an external wgpu texture panic."""


class TestCoopE2E(unittest.TestCase):
    swf = COOP_SWF

    def _has_wgpu_panic(self, event_log: Path) -> bool:
        """Return True if either Ruffle instance logged a wgpu swapchain panic."""
        for role in ("host", "client"):
            stderr_path = event_log.parent / role / "stderr.log"
            if stderr_path.is_file():
                text = stderr_path.read_text(encoding="utf-8", errors="replace")
                if "wgpu: Acquiring a texture failed" in text:
                    return True
        return False

    def _assert_procs_alive(
        self,
        procs: list[object],
        event_log: Path,
        *,
        allow_wgpu_retry: bool,
        context: str = "early",
    ) -> None:
        """Verify all Ruffle processes are still running or raise retryable wgpu error."""
        for proc in procs:
            code = proc.poll()
            if code is None:
                continue
            if allow_wgpu_retry and self._has_wgpu_panic(event_log):
                raise _RuffleWgpuRetryError(
                    f"Ruffle process {proc.pid} exited {context} with code {code} (wgpu panic)"
                )
            self.fail(f"Ruffle process {proc.pid} exited {context} with code {code}")

    def _query_qa_status(
        self,
        control_port: int,
        timeout: float = 6.0,
    ) -> tuple[dict[str, str], dict[str, str]]:
        """Send qa status to both Host and Client and wait for fresh status_ack replies."""
        before = list(control_request(control_port, {"cmd": "messages", "limit": 400}).get("messages", []))
        prev_host_acks = sum(
            1
            for m in before
            if (p := parse_coop_payload(str(m.get("payload", "")))).get("t") == "qa"
            and p.get("cmd") == "status_ack"
            and p.get("role") == "host"
        )
        prev_client_acks = sum(
            1
            for m in before
            if (p := parse_coop_payload(str(m.get("payload", "")))).get("t") == "qa"
            and p.get("cmd") == "status_ack"
            and p.get("role") == "client"
        )

        host_inj = control_request(
            control_port,
            {"cmd": "inject", "target": "host_xml", "payload": "COOP|t=qa|cmd=status"},
        )
        client_inj = control_request(
            control_port,
            {"cmd": "inject", "target": "client_xml", "payload": "COOP|t=qa|cmd=status"},
        )
        self.assertTrue(host_inj.get("ok"), f"Host status inject failed: {host_inj}")
        self.assertTrue(client_inj.get("ok"), f"Client status inject failed: {client_inj}")

        host_ack: dict[str, str] | None = None
        client_ack: dict[str, str] | None = None
        ack_deadline = time.monotonic() + timeout
        while time.monotonic() < ack_deadline:
            messages = list(control_request(control_port, {"cmd": "messages", "limit": 400}).get("messages", []))
            host_acks = [
                p
                for m in messages
                if (p := parse_coop_payload(str(m.get("payload", "")))).get("t") == "qa"
                and p.get("cmd") == "status_ack"
                and p.get("role") == "host"
            ]
            client_acks = [
                p
                for m in messages
                if (p := parse_coop_payload(str(m.get("payload", "")))).get("t") == "qa"
                and p.get("cmd") == "status_ack"
                and p.get("role") == "client"
            ]
            if len(host_acks) > prev_host_acks:
                host_ack = host_acks[-1]
            if len(client_acks) > prev_client_acks:
                client_ack = client_acks[-1]
            if host_ack is not None and client_ack is not None:
                return host_ack, client_ack
            time.sleep(0.05)

        self.fail(f"Timed out waiting for QA status_ack (host={host_ack}, client={client_ack})")

    def _assert_standing_idle(self, ack: dict[str, str], label: str) -> None:
        """Verify all living non-acting gladiators in arena are on Standing frames (1..32)."""
        self.assertEqual(ack.get("bugs"), "0", f"{label} hit bugs screen: {ack}")
        if ack.get("inArena") != "true":
            return
        turn = ack.get("turn")
        for hp_key, frame_key, actor_turn in (
            ("h1hp", "h1f", "1"),
            ("h2hp", "h2f", "2"),
            ("vhp", "vf", "3"),
        ):
            if int(ack[hp_key]) > 0 and turn != actor_turn:
                frame = int(ack[frame_key])
                self.assertGreaterEqual(frame, 1, f"{label} {frame_key}={frame} invalid while idle ({ack})")
                self.assertLessEqual(frame, 32, f"{label} {frame_key}={frame} not Standing (1..32) while idle ({ack})")

    def _run_e2e_round(
        self,
        *,
        latency_ms: float = 0.0,
        drop_rate: float = 0.0,
        timeout: float = 50.0,
    ) -> dict[str, object]:
        for attempt in range(2):
            try:
                return self._run_e2e_round_once(
                    latency_ms=latency_ms,
                    drop_rate=drop_rate,
                    timeout=timeout,
                    allow_wgpu_retry=(attempt == 0),
                )
            except _RuffleWgpuRetryError as exc:
                print(f"{exc}; retrying round once.", file=sys.stderr, flush=True)
        raise AssertionError("Unreachable retry fallthrough in _run_e2e_round")

    def _run_e2e_round_once(
        self,
        *,
        latency_ms: float = 0.0,
        drop_rate: float = 0.0,
        timeout: float = 50.0,
        allow_wgpu_retry: bool = False,
    ) -> dict[str, object]:
        with launch_pair(
            self.swf, automated=True, latency_ms=latency_ms, drop_rate=drop_rate
        ) as session:
            relay, procs, control_port, event_log = session
            deadline = time.monotonic() + timeout
            messages: list[dict[str, object]] = []
            mid_acks: tuple[dict[str, str], dict[str, str]] | None = None
            match_complete = False
            while time.monotonic() < deadline:
                self._assert_procs_alive(
                    procs,
                    event_log,
                    allow_wgpu_retry=allow_wgpu_retry,
                    context="early",
                )
                self.assertIsNone(
                    relay.poll(),
                    f"Relay exited early with code {relay.returncode}",
                )

                resp = control_request(control_port, {"cmd": "messages", "limit": 400})
                self.assertTrue(resp.get("ok"))
                messages = list(resp.get("messages", []))
                parsed = [
                    (m.get("direction", ""), parse_coop_payload(str(m.get("payload", ""))))
                    for m in messages
                ]

                sync_msgs = [p for d, p in parsed if d == "host_to_client" and p.get("t") == "sync"]
                end_msgs = [p for d, p in parsed if d == "host_to_client" and p.get("t") == "end"]

                if mid_acks is None and len(sync_msgs) >= 3 and not end_msgs:
                    try:
                        mid_acks = self._query_qa_status(control_port)
                    except self.failureException:
                        if allow_wgpu_retry and self._has_wgpu_panic(event_log):
                            raise _RuffleWgpuRetryError("Ruffle wgpu panic during mid-match status")
                        raise
                    self._assert_standing_idle(mid_acks[0], "host mid-match")
                    self._assert_standing_idle(mid_acks[1], "client mid-match")

                if end_msgs:
                    match_complete = True
                    break
                time.sleep(0.2)

            if not match_complete:
                if allow_wgpu_retry and self._has_wgpu_panic(event_log):
                    raise _RuffleWgpuRetryError("Ruffle wgpu panic before t=end")
                diagnostics = {
                    str(path.relative_to(event_log.parent)): path.read_text(
                        encoding="utf-8", errors="replace"
                    )[-1500:]
                    for path in (
                        event_log,
                        event_log.parent / "host" / "stdout.log",
                        event_log.parent / "host" / "stderr.log",
                        event_log.parent / "client" / "stdout.log",
                        event_log.parent / "client" / "stderr.log",
                    )
                    if path.is_file() and path.stat().st_size
                }
                self.fail(
                    "Timed out waiting for full multi-turn Duel completion (t=end). "
                    f"Saw types: {[parse_coop_payload(str(m.get('payload', ''))).get('t') for m in messages]}\n"
                    f"Logs and relay events: {diagnostics}"
                )

            # Allow combatwon victory sequence on both Host and Client to finish cleanly.
            time.sleep(2.0)
            try:
                host_ack, client_ack = self._query_qa_status(control_port)
            except self.failureException:
                if allow_wgpu_retry and self._has_wgpu_panic(event_log):
                    raise _RuffleWgpuRetryError("Ruffle wgpu panic before final status_ack")
                raise

            # Verify both processes stayed alive throughout.
            self._assert_procs_alive(
                procs,
                event_log,
                allow_wgpu_retry=allow_wgpu_retry,
                context="before teardown",
            )

            # Verify relayed protocol stages from event log.
            self.assertTrue(event_log.is_file(), f"Missing event log: {event_log}")
            log_events = [
                json.loads(line)
                for line in event_log.read_text(encoding="utf-8").splitlines()
                if line.strip()
            ]
            relayed_items = [
                (ev["direction"], parse_coop_payload(ev["payload"]))
                for ev in log_events
                if ev.get("event") == "relayed"
            ]

            host_hellos = [p for d, p in relayed_items if d == "host_to_client" and p.get("t") == "hello" and p.get("dna")]
            client_hellos = [p for d, p in relayed_items if d == "client_to_host" and p.get("t") == "hello" and p.get("dna")]
            host_ready = [p for d, p in relayed_items if d == "host_to_client" and p.get("t") == "ready" and p.get("ready") == "1"]
            client_ready = [p for d, p in relayed_items if d == "client_to_host" and p.get("t") == "ready" and p.get("ready") == "1"]
            starts = [p for d, p in relayed_items if d == "host_to_client" and p.get("t") == "start"]
            acts1 = [p for d, p in relayed_items if d == "host_to_client" and p.get("t") == "act" and p.get("actor") == "1"]
            acts2 = [p for d, p in relayed_items if d == "client_to_host" and p.get("t") == "act" and p.get("actor") == "2"]
            bosses = [p for d, p in relayed_items if d == "host_to_client" and p.get("t") == "boss"]
            syncs = [p for d, p in relayed_items if d == "host_to_client" and p.get("t") == "sync"]
            ends = [p for d, p in relayed_items if d == "host_to_client" and p.get("t") == "end"]

            self.assertTrue(host_hellos, "Missing Host hello with DNA")
            self.assertTrue(client_hellos, "Missing Client hello with DNA")
            self.assertTrue(host_ready, "Missing Host ready")
            self.assertTrue(client_ready, "Missing Client ready")
            self.assertEqual(len(starts), 1, f"Expected 1 start message, got {len(starts)}")

            start = starts[0]
            self.assertEqual(start.get("mode"), "duel")
            self.assertTrue(start.get("p1dna"), "Empty p1dna in start")
            self.assertTrue(start.get("p2dna"), "Empty p2dna in start")
            self.assertTrue(start.get("vdna"), "Empty vdna in start")
            self.assertGreater(int(start["seed"]), 0)

            # Require at least 2 full rounds (P1 + P2 + Boss each) and monotonic sync sequence.
            self.assertGreaterEqual(len(acts1), 2, f"Expected >=2 P1 acts, got {len(acts1)}")
            self.assertGreaterEqual(len(acts2), 2, f"Expected >=2 P2 acts, got {len(acts2)}")
            self.assertGreaterEqual(len(bosses), 2, f"Expected >=2 Boss acts, got {len(bosses)}")
            self.assertGreaterEqual(len(syncs), 6, f"Expected >=6 sync packets, got {len(syncs)}")
            self.assertEqual([int(s["seq"]) for s in syncs], list(range(1, len(syncs) + 1)))

            # Verify real movement + attack actions and resulting position/damage progression.
            all_actions = [p.get("action", "") for p in (acts1 + acts2 + bosses)]
            self.assertTrue(
                any(a in MOVEMENT_ACTIONS for a in all_actions),
                f"Expected movement action in {all_actions}",
            )
            self.assertTrue(
                any(a in ATTACK_ACTIONS or "attack" in a for a in all_actions),
                f"Expected attack action in {all_actions}",
            )
            self.assertEqual(acts1[0].get("seed"), start.get("seed"))
            for s in syncs:
                self.assertNotIn("NaN", s.values())
                for key in SYNC_PARITY_KEYS:
                    val = int(s[key])
                    if key in ("h1hp", "h2hp", "vhp", "h1arm", "h2arm", "varm"):
                        self.assertGreaterEqual(val, 0)

            self.assertGreaterEqual(
                len({(s["h1x"], s["h2x"], s["vx"]) for s in syncs}),
                2,
                f"Expected gladiator positions to change across turns: {syncs}",
            )
            # Critical hits can win a duel while the opponent still has armor.
            self.assertLess(int(syncs[-1]["vhp"]), int(syncs[0]["vhp"]), f"Enemy HP never decreased: {syncs}")

            # Verify clean Duel victory without hitting the bugs screen.
            self.assertEqual(len(ends), 1, f"Expected 1 end message, got {ends}")
            self.assertEqual(ends[0].get("outcome"), "won", f"Unexpected Duel outcome: {ends[0]}")
            self.assertEqual(host_ack.get("enabled"), "true")
            self.assertEqual(client_ack.get("enabled"), "true")
            self.assertEqual(host_ack.get("inArena"), "false")
            self.assertEqual(client_ack.get("inArena"), "false")
            self.assertEqual(host_ack.get("bugs"), "0", f"Host hit bugs screen: {host_ack}")
            self.assertEqual(client_ack.get("bugs"), "0", f"Client hit bugs screen: {client_ack}")

            # Verify exact Host and Client parity on positions, HP, armor, and turn.
            self.assertNotIn("NaN", host_ack.values())
            self.assertNotIn("NaN", client_ack.values())
            for key in SYNC_PARITY_KEYS:
                int(host_ack[key])
                int(client_ack[key])
                self.assertEqual(
                    host_ack.get(key),
                    client_ack.get(key),
                    f"Host/Client desync on {key}: host={host_ack} client={client_ack}",
                )
            self.assertEqual(host_ack["varm"], syncs[-1]["varm"])
            self.assertLess(int(host_ack["vhp"]), int(syncs[0]["vhp"]))

            return {
                "seed": start["seed"],
                "acts1": len(acts1),
                "acts2": len(acts2),
                "bosses": len(bosses),
                "syncs": len(syncs),
                "mid_checked": mid_acks is not None,
                "host_ack": host_ack,
                "client_ack": client_ack,
            }

    def test_coop_e2e_zero_latency_and_120ms_lag(self) -> None:
        base_summary = self._run_e2e_round(latency_ms=0.0, drop_rate=0.0)
        lag_summary = self._run_e2e_round(latency_ms=120.0, drop_rate=0.0)
        for key in SYNC_PARITY_KEYS:
            self.assertEqual(base_summary["host_ack"][key], base_summary["client_ack"][key])  # type: ignore[index]
            self.assertEqual(lag_summary["host_ack"][key], lag_summary["client_ack"][key])  # type: ignore[index]

    def _wait_for_status(
        self, port: int, predicate: Callable[[dict[str, str], dict[str, str]], bool]
    ) -> tuple[dict[str, str], dict[str, str]]:
        deadline = time.monotonic() + 6
        while time.monotonic() < deadline:
            host, client = self._query_qa_status(port)
            if predicate(host, client):
                return host, client
        self.fail(f"Timed out waiting for game state: host={host}, client={client}")

    def _inject(self, port: int, role: str, payload: str) -> None:
        response = control_request(port, {"cmd": "inject", "target": f"{role}_xml", "payload": payload})
        self.assertTrue(response.get("ok"), response)

    def _ready_test_gladiators(self, port: int) -> None:
        self._wait_for_status(
            port, lambda h, c: all(150 <= int(s["frame"]) < 214 for s in (h, c))
        )
        self._inject(port, "host", "COOP|t=qa|cmd=ready")
        self._inject(port, "client", "COOP|t=qa|cmd=ready")
        self._wait_for_status(port, lambda h, c: h["p2Ready"] == c["p1Ready"] == "true")

    def _enter_test_arena(self, port: int) -> tuple[dict[str, str], dict[str, str]]:
        for role in ("host", "client"):
            self._inject(port, role, "COOP|t=qa|cmd=enter_arena")
        return self._wait_for_status(
            port,
            lambda h, c: h["frame"] == c["frame"] == "226"
            and all(int(s["vf"]) in STANDING_FRAMES for s in (h, c)),
        )

    def test_host_arena_selection_matches_both_players(self) -> None:
        for arena in range(1, 7):
            with self.subTest(arena=arena):
                with launch_pair(self.swf, quick_lobby=True, latency_ms=120, ephemeral_ports=True) as session:
                    _, _, port, _ = session
                    self._ready_test_gladiators(port)
                    self._inject(port, "host", f"COOP|t=qa|cmd=host_duel|arena={arena}")
                    intro = self._wait_for_status(port, lambda h, c: h["frame"] == c["frame"] == "220")
                    for status in intro:
                        self.assertEqual(status["arena"], str(arena))
                        self.assertEqual(status["introCrowd"], str(arena))
                    for status in self._enter_test_arena(port):
                        self.assertEqual(status["arenaCrowd"], str(arena))
                        self.assertEqual(status["arenaSand"], str(arena))
                        for shadow, fighter_x in (("shadow1", "h1x"), ("shadow2", "h2x"), ("shadowV", "vx")):
                            self.assertEqual(status[shadow], f"{status[fighter_x]},200,0")

    def test_native_story_fights_and_player_hud(self) -> None:
        for mode in ("duel", "tournament"):
            with self.subTest(mode=mode):
                with launch_pair(self.swf, quick_lobby=True, latency_ms=120, ephemeral_ports=True) as session:
                    _, _, port, _ = session
                    if mode == "tournament":
                        self._inject(port, "host", "COOP|t=qa|cmd=quick_char|name=CoopP1|lvl=4")
                    self._ready_test_gladiators(port)
                    self._inject(port, "host", "COOP|t=qa|cmd=foyer")
                    self._wait_for_status(port, lambda h, c: h["foyer"] == "21")
                    selected_opponent = None
                    if mode == "tournament":
                        self._inject(port, "host", "COOP|t=qa|cmd=story_register")
                        prepared, _ = self._wait_for_status(
                            port, lambda h, c: int(h["foyer"] or 0) >= 22 and h["opponent"]
                        )
                        selected_opponent = prepared["opponent"]
                    self._inject(port, "host", f"COOP|t=qa|cmd=story_fight|mode={mode}")
                    host, client = self._wait_for_status(
                        port, lambda h, c: h["frame"] == c["frame"] == "220"
                    )
                    self.assertEqual(host["mode"], mode)
                    self.assertEqual(host["opponent"], client["opponent"])
                    if selected_opponent is not None:
                        self.assertEqual(host["opponent"], selected_opponent)
                        self.assertEqual(host["ranking"], client["ranking"])

                    # Use the same confirmation handler as the green check.
                    self._inject(port, "host", "COOP|t=qa|cmd=story_enter")
                    host, client = self._wait_for_status(
                        port, lambda h, c: h["frame"] == c["frame"] == "226"
                        and all(s["p1healthHud"] and s["p2healthHud"] for s in (h, c))
                    )
                    messages = control_request(port, {"cmd": "messages"})["messages"]
                    start = next(
                        p for message in messages
                        if (p := parse_coop_payload(message["payload"])).get("t") == "start"
                    )
                    dna = start["vdna"].split(",")
                    level, vitality, stamina = map(int, (dna[24], dna[20], dna[22]))
                    armor = sum(
                        int(dna[index]) * weight
                        for index, weight in ((6, 8), (7, 5), (8, 16), (10, 3), (11, 6), (12, 2), (14, 12))
                    )
                    helmet = int(dna[9])
                    armor += helmet * 10 if helmet <= 25 else level * 5
                    for status in (host, client):
                        self.assertEqual(int(status["vmax"]), 2 * (level * 10 + vitality * 20))
                        self.assertEqual(int(status["vsmax"]), 2 * (100 + stamina * 10))
                        self.assertEqual(int(status["vamax"]), 2 * armor)
                        self.assertEqual(status["varm"], status["vamax"])
                        self.assertTrue(status["p1healthHud"].startswith(status["h1hp"] + " / "))
                        self.assertEqual(status["p2healthHud"], f"{status['h2hp']} / {status['h2max']}")
                        self.assertEqual(status["p2energyHud"], f"{status['h2energy']} / {status['h2energymax']}")
                        self.assertEqual(status["p2armorHud"], f"{status['h2arm']} / {status['h2armormax']}")

    def test_taunt_reaction_matches_on_both_players(self) -> None:
        # These seeds exercise each reaction with two gladiators of equal charisma.
        for latency, actor, seed, reaction in (
            (0, "host", 1004, "hit"),
            (120, "client", 1000, "knockback"),
            (120, "host", 60000, "block"),
        ):
            with self.subTest(latency=latency, actor=actor, reaction=reaction):
                with launch_pair(self.swf, quick_lobby=True, latency_ms=latency, ephemeral_ports=True) as session:
                    _, _, port, _ = session
                    self._ready_test_gladiators(port)
                    messages = control_request(port, {"cmd": "messages"})["messages"]
                    dna = {
                        p["role"]: p["dna"] for message in messages
                        if (p := parse_coop_payload(message["payload"])).get("t") == "ready"
                    }
                    boss_dna = "Taunt Target," + dna["host"].split(",", 1)[1]
                    start = (
                        f"COOP|t=start|mode=duel|boss=0|arena=1|tod=24|seed={seed}"
                        f"|p1dna={dna['host']}|p2dna={dna['client']}|vdna={boss_dna}|vname=Taunt Target"
                    )
                    for role in ("host", "client"):
                        self._inject(port, role, start)
                    self._wait_for_status(port, lambda h, c: h["frame"] == c["frame"] == "220")
                    baseline, _ = self._enter_test_arena(port)
                    if actor == "client":
                        self._inject(port, "host", "COOP|t=qa|cmd=act|action=rest")
                        baseline, _ = self._wait_for_status(port, lambda h, c: h["turn"] == c["turn"] == "2")

                    self._inject(port, actor, "COOP|t=qa|cmd=act|action=taunt")
                    reactions = self._wait_for_status(
                        port,
                        lambda h, c: int(h["vf"]) in TAUNT_REACTIONS[reaction]
                        and int(c["vf"]) in TAUNT_REACTIONS[reaction],
                    )
                    for status in reactions:
                        x, y, frame = map(int, status["shadowV"].split(","))
                        self.assertEqual((y, frame), (200, 0))
                        if reaction == "knockback":
                            # The tween may advance after the shadow's enter-frame callback.
                            self.assertLessEqual(abs(x - int(status["vx"])), 20)
                    next_turn = "2" if actor == "host" else "3"
                    host, client = self._wait_for_status(port, lambda h, c: h["turn"] == c["turn"] == next_turn)
                    self.assertEqual(host["vhp"], client["vhp"])
                    self.assertEqual(host["varm"], client["varm"])
                    self.assertEqual(host["vhp"], baseline["vhp"])
                    if reaction == "hit":
                        self.assertLess(int(host["varm"]), int(baseline["varm"]))
                    else:
                        self.assertEqual(host["varm"], baseline["varm"])
                    if reaction == "knockback":
                        messages = control_request(port, {"cmd": "messages"})["messages"]
                        sync = next(
                            p for message in messages
                            if (p := parse_coop_payload(message["payload"])).get("t") == "sync"
                            and p["seq"] == "2"
                        )
                        self.assertEqual(int(sync["vx"]) - int(baseline["vx"]), 125)
                    else:
                        self.assertEqual(host["vx"], client["vx"])
                        self.assertEqual(host["vx"], baseline["vx"])

    def test_tournament_champion_and_progression_sync(self) -> None:
        for attempt in range(2):
            try:
                self._run_tournament_champion_once(allow_wgpu_retry=(attempt == 0))
                return
            except _RuffleWgpuRetryError as exc:
                print(f"{exc}; retrying tournament test once.", file=sys.stderr, flush=True)

    def _run_tournament_champion_once(self, *, allow_wgpu_retry: bool) -> None:
        with launch_pair(self.swf, quick_lobby=True, latency_ms=120, ephemeral_ports=True) as session:
            relay, procs, port, event_log = session
            try:
                self._wait_for_status(
                    port, lambda h, c: all(150 <= int(s["frame"]) < 214 for s in (h, c))
                )
                self._inject(port, "host", "COOP|t=qa|cmd=quick_char|name=CoopP1|lvl=25")
                self._inject(port, "client", "COOP|t=qa|cmd=quick_char|name=CoopP2|lvl=25")
                self._ready_test_gladiators(port)

                self._inject(port, "host", "COOP|t=qa|cmd=foyer")
                self._wait_for_status(port, lambda h, c: h["foyer"] == "21")
                self._inject(port, "host", "COOP|t=qa|cmd=story_register")
                self._wait_for_status(port, lambda h, c: int(h["foyer"] or 0) >= 22 and bool(h["opponent"]))
                self._inject(port, "host", "COOP|t=qa|cmd=set_ranking|tourney=1|ranking=2")
                self._inject(port, "host", "COOP|t=qa|cmd=story_fight|mode=tournament")

                host, client = self._wait_for_status(
                    port, lambda h, c: h["frame"] == c["frame"] == "220"
                )
                for status in (host, client):
                    self.assertEqual(status["mode"], "tournament")
                    self.assertEqual(status["tourney"], "1")
                    self.assertEqual(status["ranking"], "2")
                    self.assertEqual(status["opponent"], "John the Butcher")
                    self.assertGreater(int(status["vmax"]), 0, f"Boss HP corrupted: {status}")
                    self.assertGreater(int(status["vamax"]), 0, f"Boss armor corrupted: {status}")
                    self.assertGreater(int(status["vxp"]), 0, f"Boss XP corrupted: {status}")

                self._inject(port, "host", "COOP|t=qa|cmd=story_enter")
                host, client = self._wait_for_status(
                    port, lambda h, c: h["frame"] == c["frame"] == "226"
                    and all(int(s["vhp"] or 0) > 0 for s in (h, c))
                )
                for status in (host, client):
                    self.assertEqual(int(status["vmax"]), 220, f"Unexpected John the Butcher max HP: {status}")
                    self.assertGreater(int(status["vamax"]), 0)
                    self.assertGreater(int(status["vxp"]), 0)

                deadline = time.monotonic() + 45.0
                last_acted = None
                won = False
                while time.monotonic() < deadline:
                    self._assert_procs_alive(
                        procs,
                        event_log,
                        allow_wgpu_retry=allow_wgpu_retry,
                        context="during tournament",
                    )
                    self.assertIsNone(relay.poll(), f"Relay exited early: {relay.returncode}")

                    messages = list(control_request(port, {"cmd": "messages", "limit": 400}).get("messages", []))
                    parsed = [parse_coop_payload(str(m.get("payload", ""))) for m in messages]
                    if any(p.get("t") == "end" and p.get("outcome") == "won" for p in parsed):
                        won = True
                        break

                    h, c = self._query_qa_status(port)
                    if h["turn"] == c["turn"] and h["turn"] in ("1", "2"):
                        turn = h["turn"]
                        actor = "host" if turn == "1" else "client"
                        hp_key = "h1hp" if turn == "1" else "h2hp"
                        x_key = "h1x" if turn == "1" else "h2x"
                        frame_key = "h1f" if turn == "1" else "h2f"
                        sync_count = sum(1 for p in parsed if p.get("t") == "sync")
                        turn_token = (turn, sync_count)
                        if turn_token != last_acted and int(h[hp_key]) > 0 and int(h[frame_key]) in STANDING_FRAMES and int(c[frame_key]) in STANDING_FRAMES:
                            last_acted = turn_token
                            dist = abs(int(h["vx"]) - int(h[x_key]))
                            move_dir = "walkleft" if int(h[x_key]) > int(h["vx"]) else "walkright"
                            action = "power_attack" if dist <= 165 else move_dir
                            self._inject(port, actor, f"COOP|t=qa|cmd=act|action={action}")
                    time.sleep(0.2)

                self.assertTrue(won, "Timed out waiting to defeat Tournament Champion John the Butcher")
                h_end, c_end = self._wait_for_status(
                    port,
                    lambda h, c: h["inArena"] == c["inArena"] == "false"
                    and h["ranking"] == c["ranking"] == "1",
                )
                for label, status in (("host", h_end), ("client", c_end)):
                    self.assertEqual(status["bugs"], "0", f"{label} hit bugs: {status}")
                    self.assertEqual(status["inArena"], "false", f"{label} still in arena: {status}")
                    self.assertEqual(status["outcome"], "won")
                    self.assertEqual(status["tourney"], "1", f"{label} tourney mismatch: {status}")
                    self.assertEqual(status["ranking"], "1", f"{label} ranking not updated to 1: {status}")
                    self.assertEqual(status["inProgress"], "true", f"{label} lost tournament_in_progress: {status}")
                    self.assertEqual(status["p1Ready"], "true", f"{label} lost p1Ready: {status}")
                    self.assertEqual(status["p2Ready"], "true", f"{label} lost p2Ready: {status}")
                host_log = (event_log.parent / "host" / "stdout.log").read_text(encoding="utf-8", errors="replace")
                self.assertNotIn("combatwonitem", host_log)
            except self.failureException:
                if allow_wgpu_retry and self._has_wgpu_panic(event_log):
                    raise _RuffleWgpuRetryError("Ruffle wgpu panic during tournament test")
                raise



def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--swf", type=Path, default=COOP_SWF, help="Patched SS2 SWF under test")
    args = parser.parse_args()
    TestCoopE2E.swf = args.swf
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestCoopE2E)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if result.wasSuccessful():
        print("RESULT: PASS")
        return 0
    print("RESULT: FAIL")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
