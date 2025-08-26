# LatencyGuard - WoW Addon

## Overview

LatencyGuard is a World of Warcraft addon that automatically optimizes your gameplay experience by dynamically adjusting the 'Spell Queue Window' based on your current network latency. This helps ensure optimal spell casting responsiveness regardless of your connection quality.

## Features

- **Automatic Latency Adjustment**: Continuously monitors your network latency and adjusts SpellQueueWindow accordingly
- **Smart Zero-Latency Handling**: Special monitoring mode when zero latency is detected (common in local connections)
- **Combat-Safe Operations**: Defers all CVar changes until you're out of combat
- **Configurable Thresholds**: Set minimum latency differences required before making adjustments
- **Maximum Latency Cap**: Prevents extremely high latency spikes from setting unreasonable values
- **Debug Mode**: Comprehensive logging for troubleshooting
- **Multi-Language Support**: Localization for English, German, French, Spanish, and Russian
- **Performance Optimized**: Uses timer-based updates instead of high-frequency OnUpdate events

## Configuration

Access the configuration panel through:

- **Interface Options**: Interface -> AddOns -> LatencyGuard
- **Slash Commands**: `/lg` or `/latencyguard`

### Settings

#### Enable Latency Guard

- **Default**: Disabled
- **Description**: Master toggle for the addon functionality

#### Enable Feedback Messages

- **Default**: Disabled  
- **Description**: Shows chat messages when SpellQueueWindow is updated
- **Dependency**: Requires "Enable Latency Guard" to be enabled

#### Latency Threshold (1-50ms)

- **Default**: 1ms
- **Description**: Minimum latency change required before updating SpellQueueWindow
- **Recommendations**:
  - 1-5ms: Responsive gameplay, frequent adjustments
  - 10-20ms: Stable connections, fewer adjustments
- **Dependency**: Requires "Enable Latency Guard" to be enabled

#### Maximum Latency Cap (100-400ms)

- **Default**: 300ms
- **Description**: Maximum allowed SpellQueueWindow value to prevent extreme latency spikes from setting unreasonable values
- **Recommendations**:
  - 200-300ms: Most stable connections
  - 300-400ms: High latency or unstable connections
- **Dependency**: Requires "Enable Latency Guard" to be enabled

#### Debug Mode

- **Default**: Disabled
- **Description**: Enables detailed debug information in chat (use only for troubleshooting)
- **Warning**: Generates many chat messages
- **Dependency**: Requires "Enable Latency Guard" to be enabled

## Technical Improvements

### Performance Optimizations

- **Eliminated OnUpdate Frame**: Replaced high-frequency OnUpdate event with efficient timer-based system
- **Cached API Functions**: Pre-cached frequently used WoW API functions for better performance
- **Smart Update Logic**: Only performs updates when meaningful latency changes occur

### Error Handling & Fail Safes

- **Protected CVar Operations**: All CVar reads/writes are wrapped in pcall for error handling
- **Combat Lockdown Protection**: Automatically defers updates during combat using Dashi's defer system
- **Value Validation**: All numeric inputs are validated and clamped to safe ranges
- **Update Attempt Limiting**: Prevents infinite update loops with configurable attempt limits
- **Zero Latency Detection**: Special handling for zero latency scenarios

### Code Quality

- **Consistent camelCase Naming**: All variables and functions use proper camelCase convention
- **Comprehensive Documentation**: Inline comments explaining functionality and edge cases
- **Proper Dashi Framework Usage**: Leverages Dashi's event system, settings framework, and utilities
- **Modular Design**: Clear separation of concerns with utility functions and state management

### Enhanced Functionality

- **External Change Monitoring**: Detects when SpellQueueWindow is modified by other sources
- **Status Reporting**: Built-in GetStatus() function for debugging and monitoring
- **Multi-Timer System**: Separate timers for regular updates and zero-latency monitoring
- **Graceful Cleanup**: Proper cleanup of timers and events when addon is disabled

## Usage Examples

### Basic Usage

1. Enable "Enable Latency Guard" in the settings
2. Optionally enable "Enable Feedback Messages" to see when updates occur
3. The addon will automatically monitor and adjust your SpellQueueWindow

### Troubleshooting

1. Enable "Debug Mode" to see detailed operation logs
2. Use `/reload` after changing settings if needed
3. Check that the addon is enabled and not paused by other addons

### Advanced Configuration

- Lower latency threshold (1-2ms) for competitive gameplay requiring instant responsiveness
- Higher latency threshold (10-20ms) for casual gameplay to reduce notification frequency
- Adjust maximum latency cap based on your typical connection quality

## Compatibility

- **WoW Version**: The War Within (Interface 110002)
- **Dependencies**:
  - Dashi Framework (included)
  - LibStub (included)
  - CallbackHandler-1.0 (included)

## Developer Information

### Architecture

The addon uses the Dashi framework for:

- Event handling with automatic cleanup
- Settings management with validation
- Localization support
- Combat-safe operations with defer system

### Code Structure

```text
LatencyGuard.lua         - Main addon logic and event handlers
Config/Settings.lua      - Settings configuration and validation
Locale/Localization.lua  - Multi-language support
Libs/                    - Required libraries (Dashi, LibStub, CallbackHandler)
```

### Key Technical Decisions

1. **Timer-based instead of OnUpdate**: Reduces CPU usage from ~60fps to configurable intervals
2. **Protected CVar operations**: Prevents addon errors from game API changes
3. **Dashi framework integration**: Provides robust foundation with tested patterns
4. **Comprehensive validation**: Ensures all user inputs are safe and within game limits

## License

This addon follows standard WoW addon distribution practices. The included libraries maintain their respective licenses.

## Credits

- **Original Author**: Josh "Kkthnx" Russell
- **Framework**: Dashi by p3lim
- **Improvements**: Enhanced with modern best practices and comprehensive fail safes

---

*For support or bug reports, please check the addon's development repository or contact the maintainers.*
