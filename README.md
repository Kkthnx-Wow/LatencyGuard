# LatencyGuard

[![Last Commit](https://img.shields.io/github/last-commit/Kkthnx-Wow/LatencyGuard)](https://github.com/Kkthnx-Wow/LatencyGuard/commits/main)
[![Issues](https://img.shields.io/github/issues/Kkthnx-Wow/LatencyGuard)](https://github.com/Kkthnx-Wow/LatencyGuard/issues)
[![CurseForge](https://img.shields.io/badge/CurseForge-Download-orange)](https://www.curseforge.com/wow/addons/latencyguard)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/Kkthnx-Wow/LatencyGuard/blob/main/LICENSE)

A set-and-forget tuner for your Spell Queue Window. It adapts to your ping so your combat always feels responsive.

## What it does

- Monitors world latency and recalculates your Spell Queue Window on a 30-second cadence.
- Sets the window to your ping plus a safety margin, clamped between 100 and 400ms.
- Widens the margin when your connection gets jittery, based on your last 25 latency samples.
- Defers changes until combat ends. It never touches a protected setting mid-fight.
- Runs silently in the background with a native Blizzard settings panel.

## Get it

Install from [CurseForge](https://www.curseforge.com/wow/addons/latencyguard), or download the latest release from the [Releases](https://github.com/Kkthnx-Wow/LatencyGuard/releases) page and extract the `LatencyGuard` folder into `World of Warcraft/_retail_/Interface/AddOns`.

## Quick start

1. Install the addon and restart the game, or `/reload`.
2. Log in. LatencyGuard starts managing your Spell Queue Window right away. Nothing else to set up.
3. Open the options panel with `/latencyguard` or `/latguard` to tune the margin.
4. Run `/latencyguard status` to print a diagnostic snapshot for bug reports.

## Support the work

Free forever. If it saved you time, chip in:

- [Ko-fi](https://ko-fi.com/kkthnx)
- [Buy Me a Coffee](https://buymeacoffee.com/kkthnx)
- [PayPal](https://www.paypal.com/paypalme/kkthnxtv)

Every bit goes back into building more.

## Community

- Glitch Haven Discord: https://discord.gg/FaVGhTYmck
- Website: https://kkthnx.com

## License

Released under the MIT License. See LICENSE for details.
