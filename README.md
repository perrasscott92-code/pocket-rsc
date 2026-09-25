# Pocket RSC

**A self-hosted RuneScape Classic server running entirely on an Android phone, built on [OpenRSC](https://rsc.vet).**

Pocket RSC is a passion project. I've played RuneScape for a long time, and I wanted a private RSC world I could carry in my pocket: my own server, my own rules, no PC and no hosting bill. The phone runs the game server and the game client side by side, and one home screen icon brings the whole thing up.

None of this would exist without the OpenRSC team. After Jagex shut down RuneScape Classic in 2018, they reverse-engineered and preserved it, and they keep it free and open source. My contribution is the work that gets their server and client running together on a single Android device, plus the changes that make it feel like an app rather than a lab setup.

---

## Contents

- [Highlights](#highlights)
- [How it fits together](#how-it-fits-together)
- [Repository layout](#repository-layout)
- [Requirements](#requirements)
- [Setup](#setup)
- [Daily use](#daily-use)
- [World configuration](#world-configuration)
- [Troubleshooting journal](#troubleshooting-journal)
- [Design decisions](#design-decisions)
- [Known limitations](#known-limitations)
- [Maintenance](#maintenance)
- [Ideas for later](#ideas-for-later)
- [Credits and license](#credits-and-license)

---

## Highlights

- The OpenRSC **Core Framework** server runs on the phone itself, inside Termux and a proot Ubuntu environment
- The official OpenRSC **Android client** connects to it over `127.0.0.1`
- The client is **patched** so "Local Instance" connects to the local server without typing an address
- A **home screen icon** (a pixel-art rune 2h sword) starts the server if needed and opens the game
- An **idle watchdog** shuts the server down cleanly after 15 minutes with nobody online
- A **custom world**: 50x XP, no fatigue, skill batching, bank notes, faster walking, and more

## How it fits together

```
[Sword icon] ──> Termux:Widget runs ~/.shortcuts/RSC
                   │
                   ├─ screen "rsc"
                   │    └─ proot-distro (Ubuntu, glibc)
                   │         └─ ant runserver -DconfFile=local
                   │              └─ OpenRSC server ── TCP 43602 (game), 43496 (WebSocket)
                   │                   └─ SQLite: server/inc/sqlite/preservation.db
                   │
                   ├─ screen "rscwatch"
                   │    └─ rsc-watch.sh ── polls players.online in SQLite every 60s
                   │
                   └─ am start ──> OpenRSC Android client (patched)
                                     └─ "Local Instance" ──> 127.0.0.1:43602
```

### Ports

| Port | Purpose |
|---|---|
| 43602 | Game server (TCP). Chosen to match the client's built-in RSC Preservation slot |
| 43496 | WebSocket listener for web clients (enabled by default, unused here) |

The Android client has the official worlds' ports hardcoded, which is where 43602 came from:

| Client menu option | Host | Port |
|---|---|---|
| RSC Preservation | game.openrsc.com | 43602 |
| RSC Cabbage | game.openrsc.com | 43595 |
| RSC Uranium | game.openrsc.com | 43601 |
| RSC Coleslaw | game.openrsc.com | 43599 |
| Local Instance | user-entered (default patched to 127.0.0.1) | user-entered (default patched to 43602) |

## Repository layout

```
pocket-rsc/
├── README.md
├── .gitignore                  keeps keystores and APKs out of the repo
├── assets/
│   └── RSC.png                 256x256 home screen icon (nearest-neighbor upscale of the rune 2h sprite)
└── scripts/
    ├── configure-world.sh      builds server/local.conf with all world settings
    ├── patch-client.sh         patches and re-signs the Android client
    ├── RSC                     Termux:Widget launcher
    ├── RSC-Stop                Termux:Widget shortcut to stop the server immediately
    ├── rsc-watch.sh            idle watchdog
    └── install-termux.sh       copies the launcher, stop shortcut, watchdog, and icon into place
```

## Requirements

- An Android phone with a reasonable amount of free RAM. The server, the proot environment, and the client all run at once.
- **Termux** from [F-Droid](https://f-droid.org/packages/com.termux/). The Play Store build is outdated and its packages break.
- **Termux:Widget** from F-Droid. It must come from the same source as Termux.
- The **OpenRSC Android client APK** from [rsc.vet](https://rsc.vet).
- A file manager, to install the patched APK.

---

## Setup

Commands run in Termux unless marked **(Ubuntu)**.

### 1. Base packages and the server code

```bash
pkg update
pkg install git screen proot-distro sqlite make ant openjdk-21
termux-setup-storage
git clone https://github.com/Open-RSC/Core-Framework.git
```

### 2. Ubuntu runtime

```bash
proot-distro install ubuntu
proot-distro login ubuntu --bind ~/Core-Framework:/root/Core-Framework
```

**(Ubuntu)**

```bash
apt update && apt install -y openjdk-21-jdk-headless ant screen
cd /root/Core-Framework
ant -f server/build.xml compile_core
```

The first `apt install` stops to ask for a timezone. Answer it before pasting anything else, or the next lines get swallowed by the prompt.

### 3. World config

```bash
cd ~/Core-Framework/server
bash /path/to/pocket-rsc/scripts/configure-world.sh
```

### 4. First server run

**(Ubuntu)**

```bash
cd /root/Core-Framework/server
ant runserver -DconfFile=local
```

The server is ready when it logs:

```
Game world is now online on TCP port 43602!
RSC Preservation started in 3115ms
```

Stop it with Ctrl+C once you've confirmed it works.

### 5. Patch the client

Copy the downloaded client into the shared folder so Ubuntu can reach it:

```bash
cp ~/storage/downloads/openrsc.apk ~/Core-Framework/
```

**(Ubuntu)**

```bash
apt install -y apktool apksigner zipalign
cd /root/Core-Framework
bash /path/to/pocket-rsc/scripts/patch-client.sh openrsc.apk
exit
```

Back in Termux:

```bash
cp ~/Core-Framework/openrsc-local.apk ~/storage/downloads/
```

Uninstall the stock OpenRSC app, then install `openrsc-local.apk` from Downloads. The re-signed APK can't install over the original because the signatures differ.

### 6. Launcher, watchdog, and icon

```bash
bash /path/to/pocket-rsc/scripts/install-termux.sh
```

Then:

1. Android Settings → Apps → Termux → turn on **Display over other apps**, so the script can open the game.
2. Long-press the home screen → Widgets → Termux:Widget → drag out the single **shortcut** widget → choose **RSC**. Add another for **RSC-Stop** if you want a stop button.

### 7. First login

Tap the sword, choose **Local Instance**, leave both boxes blank, and tap **Enter**. Register a character with **New User**. There's a "skip tutorial" option in the in-game options menu, above logout.

---

## Daily use

| Task | How |
|---|---|
| Play | Tap the sword icon |
| Stop now | Tap RSC-Stop, or swipe the game away and let the watchdog stop it after 15 minutes |
| Check whether it's running | `screen -ls` (look for `rsc` and `rscwatch`) |
| Watch the server log | `screen -r rsc`, then Ctrl+A then D to detach without stopping it |
| Manual stop | `screen -S rsc -X stuff $'\003'`, wait a moment, then `screen -S rsc -X quit` |

### Admin rank

Log out first. Otherwise the game saves over the change when your character saves.

```bash
sqlite3 ~/Core-Framework/server/inc/sqlite/preservation.db \
  "update players set group_id=0 where username='YourName';"
```

---

## World configuration

`configure-world.sh` copies `preservation.conf` to `local.conf` and edits it. The server loads `local.conf` over `default.conf`, so the defaults stay intact as a fallback.

| Setting | Value | Why |
|---|---|---|
| `server_port` | 43602 | Matches the client's Preservation slot and the patched default |
| `enforce_custom_client_version` | false | The Android client reports a different version than the config expects |
| `is_localhost_restricted` | false | Every connection on-device comes from 127.0.0.1 |
| `network_flood_ip_ban_minutes` | 0 | One shared IP, so a flood ban only locks out the owner |
| `suspicious_player_ip_ban_minutes` | 0 | Same reason |
| `combat_exp_rate` / `skilling_exp_rate` | 50 | 50x XP |
| `want_fatigue` | false | At 50x, fatigue would max out almost immediately |
| `batch_progression` | true | One click keeps a skilling action going |
| `experience_drops_toggle` / `experience_counter_toggle` | true | Shows XP gains |
| `want_bank_notes` / `want_cert_deposit` | true | Easier banking |
| `want_equipment_tab` | false | Needs an `equipped` table the Preservation SQLite database does not have; enabling it breaks character loading |
| `want_bank_presets` | false | Enabling it breaks the logout save (NullPointerException in `querySavePlayerBankPresets`), leaving players stuck "still logged in" |
| `want_decanting` | true | Combine potions |
| `want_improved_pathfinding` | true | A* pathing when chasing NPCs |
| `want_skill_menus` / `want_quest_menus` | true | In-game guides |
| `ground_item_toggle` / `show_roof_toggle` | true | Client toggles |
| `want_custom_walking_speed` / `walking_tick` | true / 400 | Faster walking (default tick is 640) |
| `idle_timer` | 0 | No 5-minute idle alert |
| `want_pcap_logging` | false | Stops packet logs from filling phone storage |
| `want_discord_*` | false | No webhook configured, so these only produce errors |

Runecraft, Harvesting, and pets are commented out in the script and can be switched on.

Some `client:` toggles come from the PC client, and the Android client is an older port, so not all of them appear on the phone. Server-side settings such as XP, batching, and bank notes apply regardless.

---

## Troubleshooting journal

Every problem below actually happened during the build. Each entry lists the symptom, what caused it, and the fix.

**`./Start-Linux.sh: line 35: make: command not found`**
The helper script uses `make`, which Termux doesn't include by default.
Fix: `pkg install make`.

**`We cannot run Java, please ensure you have Java installed`**
Ant couldn't locate the JDK even though `java -version` worked.
Fix: `export JAVA_HOME=$PREFIX/lib/jvm/java-21-openjdk`, and add it to `~/.bashrc`.

**`java.awt.HeadlessException: No X11 DISPLAY variable was set`**
The "single player edition" option launches the PC client alongside the server, and Termux has no display.
Fix: Use the server-only option, or run the server command directly.

**`screen -ls` shows `No Sockets found` right after starting**
The server was crashing on startup inside a detached `screen` session, and the error disappeared with the session.
Fix: I traced `Start-Linux.sh` → `Deployment_Scripts/run.sh` → `server/ant_launcher.sh` to find the real command, `ant runserver -DconfFile=local`, and ran it in the foreground to see the error.

**`No native library found for os.name=Linux, os.arch=aarch64` / `Unable to connect to SQLite`**
The server's SQLite driver (`sqlite-jdbc`) bundles a native library built for glibc. Termux uses Android's Bionic libc, so the library won't load.
Fix: Run the server inside Ubuntu via `proot-distro`, with the project folder bind-mounted. This was the turning point of the project.

**`Registration failed: Registered recently` / "wait an hour" in the client**
I first assumed a real one-hour throttle on registrations. Querying the database showed there were no accounts at all, so old registrations weren't the cause. Every connection came from `127.0.0.1`, which the server treats as a restricted address by default.
Fix: `is_localhost_restricted: false`.

**Logged in, disconnected immediately, told to wait a few minutes**
The repeated registration attempts from the same IP tripped the network flood ban.
Fix: Set both IP ban durations to 0, which is safe for a private, single-user server.

**`Permission Denial: ... GameActivity ... not exported`**
I tried launching the client's game screen directly to skip the world menu. Android only allows the app itself to open that screen.
Fix: None possible from outside the app, which led to the client patch below.

**Local Instance asks for an IP and port every launch**
Reading `CacheUpdater.java` showed the dialog never saves what you type. Blank boxes fall back to hardcoded defaults of `192.168.1.100` and `43594`.
Fix: Decompile with apktool, replace those two constants in the smali (`CacheUpdater$UpdateTask.smali`), then rebuild, zipalign, and re-sign.

**`Error: Activity class {...ApplicationUpdater} does not exist`**
The stock app had been uninstalled, and the patched one wasn't installed yet, because the copy to Downloads never ran.
Fix: Copy the APK to Downloads and install it.

**"Already logged in"**
A stale session left over from the earlier disconnect.
Fix: Wait a minute or restart the server.

**Login loop, "still logged in," null inventory and bank errors**
The log showed `no such table: equipped` at login. The equipment tab and bank presets need database tables the Preservation SQLite database does not have, so characters failed to load and every save rolled back.
Fix: `want_equipment_tab: false` and `want_bank_presets: false`.

**Termux gotchas worth knowing**
- If a command stops for input partway through a pasted block (like the Ubuntu timezone prompt), the rest of the block gets typed into that prompt instead of running.
- Anything pasted after `exit` in a proot session may never run in Termux. Run the next commands separately.
- `~/storage/downloads` exists only in Termux, not inside proot, unless you bind-mount it.

---

## Design decisions

**proot Ubuntu instead of switching to MariaDB.** The server also supports MySQL/MariaDB, which avoids the SQLite native library problem. That route means running and maintaining a second service and importing schemas. proot fixed the root cause with one bind mount and kept the default SQLite setup.

**Patching the client instead of redirecting DNS.** The stock client resolves `game.openrsc.com` for its built-in worlds, so pointing that hostname at `127.0.0.1` would also work. On Android, that needs a local-VPN DNS app, and Android allows only one VPN at a time, so it would conflict with a regular VPN. Changing two string constants in the client has no ongoing cost.

**A database-polling watchdog instead of detecting when the app closes.** Termux can't see which app is in the foreground without root. The server does record who's online in SQLite, so polling `players.online` is a reliable proxy. Swiping the game away disconnects the player, and the watchdog takes it from there.

**A clean shutdown instead of killing the process.** The watchdog and the stop shortcut send Ctrl+C to the server's screen session first, so the server runs its shutdown and saves, and only then close the session.

---

## Known limitations

- Leaving the game in the background without swiping it away can keep the connection open, which keeps the server running.
- The patched client is signed with a personal key, so it won't take updates over the official build. Re-run `patch-client.sh` on each new client release.
- proot adds some overhead compared to native execution. It's fine for a single player.
- The watchdog has a 4-minute startup grace period before it starts counting idle time.
- The sleep in the launcher is a fixed 20 seconds. A slower phone might need more.

---

## Maintenance

### Updating OpenRSC

```bash
cd ~/Core-Framework && git pull
```

**(Ubuntu)**

```bash
cd /root/Core-Framework && ant -f server/build.xml compile_core
```

`local.conf` is left alone by `git pull`. New upstream options appear in `preservation.conf` and `default.conf`, so compare them occasionally.

### Backing up your character

```bash
sqlite3 ~/Core-Framework/server/inc/sqlite/preservation.db \
  ".backup '/sdcard/Download/preservation-backup.db'"
```

---

## Ideas for later

- **Termux:Boot** to start the server when the phone boots
- **Tailscale** so friends can join the world from their own devices
- A **web client** using the WebSocket listener on 43496
- A **world switcher** that can run the Cabbage or 2001scape presets from the same launcher
- **Notifications** when the watchdog shuts the server down

---

## Credits and license

- **[OpenRSC](https://rsc.vet)** for the server, the Android client, and years of preservation work. OpenRSC is licensed under **AGPL-3.0**, and the scripts and modifications in this repo are shared under the same license.
- RuneScape and RuneScape Classic are trademarks of **Jagex Ltd.** This is a non-commercial, private hobby project and is not affiliated with or endorsed by Jagex or the OpenRSC team.
- This repo contains documentation, scripts, and an icon only. It does not redistribute game assets, a prebuilt client, or signing keys.
