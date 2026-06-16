<div align="center">

# LatencyGuard

**A lightweight, set-and-forget tuner for your Spell Queue Window — it adapts to your ping so your combat always feels snappy.**

[![Last Commit](https://img.shields.io/github/last-commit/Kkthnx-Wow/LatencyGuard)](https://github.com/Kkthnx-Wow/LatencyGuard/commits/main)
[![Issues](https://img.shields.io/github/issues/Kkthnx-Wow/LatencyGuard)](https://github.com/Kkthnx-Wow/LatencyGuard/issues)
[![CurseForge](https://img.shields.io/badge/CurseForge-Download-orange)](https://www.curseforge.com/wow/addons/latency-guard)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/Kkthnx-Wow/LatencyGuard/blob/main/LICENSE)

</div>

---

## Overview

The **Spell Queue Window** is a hidden game setting (`SpellQueueWindow`) that controls the "buffer time" the game gives you to queue your next ability before the current one finishes. Set it too low and your rotation feels clunky and drops casts; set it too high and you lose precise control. The catch is that the *ideal* value depends entirely on your **world latency** — which changes from zone to zone, fight to fight, and day to day.

**LatencyGuard** solves that for you. It monitors your real-time world ping and continuously recalculates the optimal queue window — your ping plus a tolerance buffer of your choosing — so your gameplay stays responsive without losing the ability to queue spells effectively. High latency automatically gets a wider window; low latency gets a tighter one. You set it once and forget it.

- **Set-and-forget** — no math, no `/console` commands, no guessing. It just keeps the right value applied.
- **Adaptive** — recalculates from your live world latency, so it tracks your connection as it changes.
- **Combat-safe** — never touches a protected CVar mid-fight; pending changes are deferred until combat ends.
- **Performance-first** — event-driven with a low-frequency maintenance tick, local caches, and a change threshold so it only writes when it actually matters.
- **Native settings** — a clean options panel built on Blizzard's own Settings API.

---

## Installation

**Via an addon manager (recommended)**
- [CurseForge](https://www.curseforge.com/wow/addons/latencyguard) — search for **LatencyGuard** and install.

**Manual**
1. Download the latest release from the [Releases](https://github.com/Kkthnx-Wow/LatencyGuard/releases) page.
2. Extract the `LatencyGuard` folder into `World of Warcraft\_retail_\Interface\AddOns`.
3. Restart the game (or `/reload` if already in-game).

There's nothing to configure to get the benefit — LatencyGuard starts managing your Spell Queue Window the moment you log in. Tweak the behavior anytime with `/lg`.

---

## Getting Started

| Command | Description |
| --- | --- |
| `/lg` | Open the options panel |
| `/latencyguard` | Open the options panel |

On login (with chat feedback enabled) LatencyGuard prints a short confirmation and the `/lg` hint. From then on it works quietly in the background.

---

## Features

### Automatic Tuning
- **Adaptive Spell Queue Window** — reads your world latency and sets `SpellQueueWindow` to `ping + tolerance`, recalculated on a steady maintenance cycle so it always reflects your current connection.
- **Smart clamping** — the target is kept within a sensible **100–400ms** range, so a latency spike (or a near-zero reading) can never push you to an unusable value.
- **Change threshold (hysteresis)** — the addon only rewrites the CVar when the new target differs from the current value by a meaningful amount, avoiding constant churn from tiny ping fluctuations.
- **Latency discovery** — `GetNetStats` only refreshes world latency periodically, so right after login (when no reading is available yet) LatencyGuard briefly polls until it gets a valid number, then settles into its normal cadence.

### Combat Safety
- **Deferred writes** — `SpellQueueWindow` can't be changed while you're in combat. If an update is due mid-fight, LatencyGuard flags it and applies it the instant combat ends (`PLAYER_REGEN_ENABLED`).
- **Midnight-ready** — built for the current client, with a defensive guard against the 12.0 Secret Values model so a future API change can never break the addon.

### Options
- **Automate Spell Queue Window** — the master switch. When off, LatencyGuard stops all adjustments immediately and leaves your CVar alone.
- **Tolerance Buffer** — the value added to your world ping (0–300ms, default **150**). Higher values (200+) are safer for high-latency connections; lower values (50–100) suit high-end competitive play.
- **Chat Feedback** — optionally print a line whenever the queue window is updated, showing the new value, your ping, and the buffer used.

### Localization
- Ships with translations for **enUS, deDE, esES, esMX, frFR, itIT, koKR, ptBR, ruRU, trTR, zhCN, and zhTW**, with a graceful English fallback for any missing strings.

---

## Configuration

Open the panel with **`/lg`** (or through the Blizzard AddOns settings). The main page explains what the Spell Queue Window is and why the addon exists; the **Options** subcategory holds the live toggles:

| Setting | Default | What it does |
| --- | --- | --- |
| Automate Spell Queue Window | On | Enables/disables all automatic adjustments |
| Tolerance Buffer | 150ms | Added to your world ping when computing the target window |
| Enable Chat Feedback | On | Prints a message each time the window is updated |

All settings apply **live** — there's nothing to reload.

---

## How It Works

1. **Measure** — `GetNetStats()` reports your average world latency (the game refreshes this roughly every 30 seconds).
2. **Calculate** — LatencyGuard computes `target = worldPing + tolerance`, then clamps it into the safe **100–400ms** range.
3. **Compare** — it checks the target against your current `SpellQueueWindow`. If the difference is below the change threshold, it does nothing.
4. **Apply** — otherwise it writes the new value — but only out of combat. If you're mid-fight, the change waits until combat ends.

The result: a Spell Queue Window that's always matched to your actual connection, with zero manual upkeep.

---

## Contributing

Contributions, bug reports and ideas are welcome! Open an [issue](https://github.com/Kkthnx-Wow/LatencyGuard/issues) or a pull request. When filing a bug, including your client version, your typical world latency, and a `/reload`-able repro helps a ton.

---

## Support

Appreciate the work that goes into LatencyGuard? Consider showing your support:

- **PayPal** — [paypal.me/KkthnxTV](https://www.paypal.com/paypalme/kkthnxtv)
- **Patreon** — [patreon.com/Kkthnx](https://www.patreon.com/Kkthnx)
- **Battle.net / Balance** — `Kkthnx#1105` or `JRussell20@gmail.com`
- **In-game gold** — Kkthnx on Area 52 (US)

---

## License

Released under the **MIT License**.

<div align="center">

Developed and maintained by **Josh "Kkthnx" Russell**. Built with love for a snappier combat feel.

</div>
