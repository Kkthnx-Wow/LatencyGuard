# LatencyGuard

[![Last Commit](https://img.shields.io/github/last-commit/Kkthnx-Wow/LatencyGuard)](https://github.com/Kkthnx-Wow/LatencyGuard/commits/main)
[![Issues](https://img.shields.io/github/issues/Kkthnx-Wow/LatencyGuard)](https://github.com/Kkthnx-Wow/LatencyGuard/issues)
[![CurseForge](https://img.shields.io/badge/CurseForge-Download-orange)](https://www.curseforge.com/wow/addons/latency-guard)

Keeps your Spell Queue Window matched to your connection and shows you what that connection is doing. For World of Warcraft Retail and WoW Forever.

## Why it matters

The Spell Queue Window lets you press your next ability a little before the current cast or global cooldown ends, so it fires with no gap. The game default is 400ms for everyone. On a 30ms connection that commits you to your next press far too early, which makes reacting to procs and interrupts harder. On an unstable connection a window that is too small drops presses. LatencyGuard sets it for you and keeps it right as your connection changes.

## What it does

- Sets the window to your world latency plus a safety margin, kept between 100 and 400ms.
- Uses a separate, tighter margin in arenas and battlegrounds if you want one.
- Adds headroom when your latency readings are uneven, up to 150ms.
- Widens at once when needed and waits 45 seconds before narrowing, so a short calm does not remove protection right before the next spike.
- Changes the setting only out of combat.
- Steps aside for 10 minutes when another addon, a macro or the console changes the window, instead of fighting over it.
- Puts back your own value when you turn automation off.

## What it shows

- An optional movable readout with world latency, frame rate and the current Spell Queue Window. Hover it for the full report. While hidden it does no work at all.
- A live report on its options page and through `/latencyguard status`. It covers world and home latency, latency range and spread, bandwidth, frame rate with average and low, the target and how it was worked out, and your Low Latency Mode setting.
- An optional chat alert when world latency spikes past a threshold you choose, and another when it settles.
- A data broker feed for broker bars and data texts.

The game refreshes its latency figure about every 30 seconds, so everything above moves at that pace. LatencyGuard does not invent faster numbers.

## Install

Install from [CurseForge](https://www.curseforge.com/wow/addons/latency-guard), or download the latest zip from [Releases](https://github.com/Kkthnx-Wow/LatencyGuard/releases) and extract the `LatencyGuard` folder into your AddOns folder.

- Retail: `World of Warcraft/_retail_/Interface/AddOns`
- WoW Forever: `World of Warcraft/_forever_/Interface/AddOns`

## Use

It works as soon as you log in. Open the options with `/latencyguard` or `/latguard`.

| Command | What it does |
| --- | --- |
| `/latencyguard` | Open the options |
| `/latencyguard status` | Print the live report |
| `/latencyguard readout` | Show or hide the readout |
| `/latencyguard resume` | End a pause caused by an outside change |
| `/latencyguard restore` | Turn automation off and put back your own value |
| `/latencyguard reset` | Clear latency and frame rate samples |

Suggested safety margins are 30 to 70ms for reactive PvP, 70 to 130ms for most play and 100 to 150ms for steady PvE.

## Development

The addon is plain Lua 5.1 with no build step. Before a release:

```
luacheck .
lua5.1 tests/run.lua
lua5.1 tests/run.lua . fresh
```

The tests load every file in TOC order against a stubbed game API and drive events, timers and settings. They check logic, not in-game behavior.

To release, set `## Version` in `LatencyGuard.toc`, commit, then push an annotated tag with the same number. The release workflow lints, tests, packages and uploads to GitHub Releases and CurseForge.

```
git tag -a 3.0.0 -m "3.0.0"
git push origin 3.0.0
```

## Support the work

Free forever. If it helps, you can chip in:

- [Ko-fi](https://ko-fi.com/kkthnx)
- [Buy Me a Coffee](https://buymeacoffee.com/kkthnx)
- [PayPal](https://www.paypal.com/paypalme/kkthnxtv)

## Community

- Glitch Haven Discord: https://discord.gg/FaVGhTYmck
- Website: https://kkthnx.com
