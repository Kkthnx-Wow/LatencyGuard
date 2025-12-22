# LatencyGuard

**LatencyGuard** is a high-performance World of Warcraft addon designed to eliminate input lag and optimize spell-casting responsiveness. It dynamically synchronizes the game's hidden `SpellQueueWindow` (SQW) with your real-time world latency, ensuring your ability queuing is always mathematically optimized for your current connection.

---

## Key Features

* **Dynamic Synchronization:** Automatically calculates and applies the optimal Spell Queue Window based on real-time world ping.
* **Intelligent Discovery:** Features a high-frequency "Cold Start" mode to capture reliable data immediately upon login or instance transitions.
* **Combat Safety:** Strictly respects WoW's combat lockdown rules, deferring CVar updates until the player has left combat.
* **Jitter Prevention:** Uses hysteresis logic to avoid constant, minor updates to the game engine, only applying changes when network conditions shift significantly.
* **Modular Architecture:** Built with a clean, production-grade codebase designed for maximum performance and zero global namespace pollution.

---

## Configuration

Access the settings panel to fine-tune your experience:

* **Slash Commands:** `/lg` or `/latencyguard`
* **Menu Path:** `Escape` > `Options` > `AddOns` > `LatencyGuard`

### Core Settings

| Setting | Description | Recommended |
| :--- | :--- | :--- |
| **Enable Automation** | Master toggle for the logic loop. | Enabled |
| **Chat Feedback** | Prints a message when SQW is adjusted. | Enabled (Verbose) |
| **Tolerance Buffer** | The "padding" added to your current ping. | 100ms - 150ms |

---

## Technical Specifications

### Performance Engineering
* **Event-Driven:** Replaces heavy `OnUpdate` polling with an efficient dual-ticker system (30s Maintenance / 2s Discovery).
* **Zero GC Footprint:** Pre-cached API globals and table reuse prevent memory churn and Lua garbage collection spikes.
* **Namespace Discipline:** Uses a private namespace table to ensure zero conflicts with other addons or the Blizzard UI.

### Compatibility
* **Retail:** Fully supports *The War Within* (Interface 11.x) using the modern Settings API.
* **Classic:** Support for *Classic Era*, *Season of Discovery*, and *Cataclysm Classic*.

---

## Installation

1.  Download the latest release from [GitHub](https://github.com/Kkthnx-Wow/LatencyGuard/releases).
2.  Extract the `LatencyGuard` folder into your `Interface\AddOns\` directory.
3.  Restart World of Warcraft.

---

## Credits & Support

**Author:** Josh "**Kkthnx**" Russell  
**License:** Standard WoW Addon Distribution License.

[![Donate via PayPal](https://img.shields.io/badge/Donate-PayPal-blue.svg)](https://www.paypal.me/KkthnxTV)
[![Support on Patreon](https://img.shields.io/badge/Support-Patreon-orange.svg)](https://www.patreon.com/Kkthnx)

*For bug reports or feature requests, please visit the [GitHub Issue Tracker](https://github.com/Kkthnx-Wow/LatencyGuard/issues).*
