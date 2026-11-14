# Swords and Sandals 2 — 2v1 Tailscale Co-op

Online 2v1 Co-op mod and Tailscale TCP/XMLSocket relay for **Swords and Sandals Classic Collection** (Swords and Sandals II: Emperor's Reign).

## Requirements

- Windows with **Swords and Sandals Classic Collection** (Steam AppID `1055430`)
- **Python 3.14** (or 3.10+, zero external pip dependencies)
- **Tailscale** installed and signed in on both players' PCs

## 1. Install / Uninstall the Co-op SWF

Run from `c:\Users\PC\Desktop\Projeler\COOPS\ss2-coop`:

- **Install** (verifies stock SWF SHA-256, backs up to `swf\swords_sandals2_download.swf.bak`, verifies `dist\manifest.json`, and installs `dist\swords_sandals2_coop.swf`):
  - Double-click `install_coop.bat`, or run:
    ```powershell
    powershell -ExecutionPolicy Bypass -File .\install_coop.ps1
    ```
  - Optional custom Steam folder:
    ```powershell
    .\install_coop.ps1 -GameDir "D:\SteamLibrary\steamapps\common\Swords and Sandals Classic Collection"
    ```
- **Uninstall** (restores `swords_sandals2_download.swf.bak` -> `swords_sandals2_download.swf` and removes co-op metadata):
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\uninstall_coop.ps1
  ```

## 2. Playing Co-op over Tailscale

Both players should launch `START_COOP.bat` (or `python src\launcher\ss2_coop_launcher.py`; pass `--cli` for terminal mode).

### Host (Player 1)

1. Open `START_COOP.bat`. Your Tailscale IPv4 (`100.x.y.z:19850`) is detected automatically — click **Copy IP:Port** and send it to your friend.
2. Click **Host Co-op** (starts the relay bridging `0.0.0.0:19850` <-> `127.0.0.1:19801`).
3. Click **Launch SS2 (Steam)** (or launch the game from Steam).
4. In-game, create or load a gladiator, open the **Co-op** panel, select **Host Co-op (19801)**, then **Ready Up**.
5. Once both players are ready, use **Enter the Arena** in Town Square. Choose the game's **Duel**, or register for a **Tournament** and select its fight. Confirm the opponent with the green check to enter the arena together.

### Client (Player 2)

1. Open `START_COOP.bat`.
2. Paste the Host's `Tailscale IP:port` (e.g., `100.91.119.94:19850`) into **Host IP:Port**.
3. Click **Join Co-op** (starts the relay bridging `<host_ip>:19850` <-> `127.0.0.1:19802`).
4. Launch the game from Steam, create/load a gladiator, open the **Co-op** panel, click **Join Co-op (19802)**, and click **Ready**.

## 3. Local game testing with Ruffle

On Windows, run these commands from `COOPS\ss2-coop` with Python 3.10 or newer.
The local launcher uses the bundled Ruffle executable and `dist\swords_sandals2_coop.swf`
and binds the relay to loopback. It can run without Steam or Tailscale.

```powershell
# Open a Host window on the left and a Client window on the right
python tools\runner\local_qa.py

# Enter Town Square with two connected test gladiators
python tools\runner\local_qa.py --lobby

# Run a manual session with 120 ms of simulated one-way latency
python tools\runner\local_qa.py --lobby --latency-ms 120

# Run automated 2v1 duels at 0 ms and 120 ms, then close both clients
python tests\test_coop_e2e.py
```

For the full game flow, create a gladiator and win the tutorial fight in each
window. In Town Square, open **2v1 CO-OP LOBBY**, select **Host Co-op (19801)** on
the left and **Join Co-op (19802)** on the right. With `--lobby`, both players
are already connected when Town Square loads.

Select **Ready Up** in both windows. On the host, open **Enter the Arena** and
choose the duel or next tournament fight. The host confirms the opponent for
both players. In combat, the left panel shows P1 and the center panel shows
P2's health, energy and armor. The opponent's maximum health, energy and
armor scale with the number of players at the start of the fight.

Close either window or press Ctrl+C to stop the two clients and relay.

Each session prints its log directory under `local\qa_runs`. The relay writes
`events.jsonl`, and each player has their own Ruffle logs, configuration, and
cache. Game saves are kept in memory for that session. Use `--swf PATH` with
either launcher to test a separately built co-op SWF.

To test ActionScript changes, build from the stock copy into the local directory.
This requires Java and the bundled FFDEC.

```powershell
python src\swf_patch\build_swf.py --src local\test_env\host\swf\swords_sandals2_download.swf --out local\swords_sandals2_qa.swf
python tests\test_coop_e2e.py --swf local\swords_sandals2_qa.swf
```

The automated duels check that both clients complete a fight and agree on
positions, health, armor, and turn. Automated and `--lobby` sessions retry
startup once if either player fails to connect to the relay.

## 4. Relay CLI

```powershell
# Host relay (Tailscale IP auto-detected)
python src\relay\ss2_coop_relay.py host

# Join relay
python src\relay\ss2_coop_relay.py join --connect 100.91.119.94:19850

# 1-PC local QA bridge with optional lag/drop simulation and JSONL event log
python src\relay\ss2_coop_relay.py local-pair --latency-ms 120 --drop-rate 0 --control-port 19890 --event-log local\qa_events.jsonl
```

## 5. Running the full Co-op suite

```powershell
python -m unittest discover -s tests -p "test_*.py" -v
```
