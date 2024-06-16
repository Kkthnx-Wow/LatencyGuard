# Latency Guard
![ability_warrior_shieldguard](https://github.com/Kkthnx-Wow/LatencyGuard/assets/40672673/a12a84e0-9781-490b-804b-60dc8d0c2368)

Latency Guard optimizes your gameplay experience by dynamically adjusting the 'Spell Queue Window' based on your current network latency.

## Overview

Latency Guard helps you maintain an optimal gaming experience by automatically adjusting the `Spell Queue Window` to match your network latency. This adjustment ensures that your spells and abilities are executed with minimal delay, providing a smoother and more responsive gameplay experience.

## Features

- **Dynamic Latency Adjustment**: Automatically updates the `Spell Queue Window` based on your current network latency.
- **Zero Latency Detection**: Handles cases where latency drops to zero by starting a periodic check to ensure accurate updates.
- **User Feedback**: Optionally receive feedback messages when the `Spell Queue Window` is updated.
- **Combat Safe**: Queues updates during combat and processes them once combat ends.

## Installation

1. Download the latest version of Latency Guard from [GitHub Releases](https://github.com/Kkthnx-Wow/LatencyGuard/releases).
2. Extract the downloaded zip file.
3. Copy the `LatencyGuard` folder to your World of Warcraft Addons directory:
   - _Windows_: `C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\`
   - _Mac_: `/Applications/World of Warcraft/_retail_/Interface/AddOns/`

4. Restart World of Warcraft or reload your UI with `/reload`.

## Usage
Latency Guard works in the background once enabled. You can configure it through the provided options to suit your needs. The addon will automatically adjust the Spell Queue Window based on your current latency, ensuring an optimized gameplay experience.

## License
This project is licensed under the MIT License. See the LICENSE file for details.
