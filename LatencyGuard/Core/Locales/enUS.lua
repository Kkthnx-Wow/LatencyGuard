--[[
	LatencyGuard - Localization (enUS / fallback)
	-------------------------------------------------------------------------
	Every user-facing string lives here. Other locales overwrite only the keys
	they translate.
--]]

local _, ns = ...
local L = ns.L

-- General
L["General"] = "General"
L["Version"] = "Version"
L["Author"] = "Author"
L["Getting Started"] = "Getting Started"
L["Usage"] = "Usage"
L["Show this help"] = "Show this help"
L["Show diagnostic status"] = "Print ping, spell queue, and addon state for troubleshooting"
L["Open the options panel"] = "Open the options panel"
L["Yes"] = "yes"
L["No"] = "no"

L["DESC_GENERAL"] = "Spell Queue Window tuning based on your live world latency."

-- Landing page
L["Landing Status"] = "World latency: %s   Spell queue: %s"
L["Landing Term SQW"] = "Spell Queue Window"
L["Landing Term World Latency"] = "world latency"
L["Landing Term Jitter"] = "2 × jitter"
L["Landing Section How"] = "How it works"
L["Landing Section How Body"] = "The %s is an input buffer — not a lag reducer. During the last N milliseconds of your cast or GCD, the server accepts your next ability.\n\n|cffffffff1.|r Press inside the window.\n|cffffffff2.|r Your command travels while the current spell finishes.\n|cffffffff3.|r The next spell fires the instant you're allowed — no dead gap."
L["Landing Section Tradeoff"] = "The sweet spot"
L["Landing Section Tradeoff Body"] = "|cffaaaaaaToo small:|r your packet arrives after the window closes → missed queues and GCD gaps.\n|cffaaaaaaToo large:|r you commit earlier → harder to react to procs, interrupts, and priority swaps.\n\nMost players land near |cffffffffworld ping + ~100ms|r. Reactive specs run tighter; stable PvE can go wider."
L["Landing Section Addon"] = "What LatencyGuard does"
L["Landing Section Addon Body"] = "Reads %s (combat traffic — not home/realm chat) and keeps your queue matched:\n\n|cff2dd4bfSQW = ping + safety margin|r (+ %s when adaptive jitter is on)\n\nClamped to 100–400ms. Updates only out of combat. Open |cffc9a227General|r to tune margin and jitter."
L["Landing Footer"] = "%s  ·  %s  ·  %s for diagnostics"
L["Pending"] = "pending..."

-- Module
L["Spell Queue"] = "Spell Queue"
L["Automate Spell Queue Window"] = "Automate Spell Queue Window"
L["Automate Spell Queue Window Tooltip"] = "When enabled, LatencyGuard manages all Spell Queue Window adjustments.\n\n|cffff0000Note:|r Disabling this stops all updates immediately."
L["Enable Chat Feedback"] = "SQW Update Messages"
L["Enable Chat Feedback Tooltip"] = "Print a message when the Spell Queue Window is changed. No message is shown on login."
L["Tolerance Buffer"] = "Safety Margin"
L["Tolerance Buffer Tooltip"] = "Base headroom added to world latency. Adaptive Jitter adds 2×σ on top when enabled.\n\nReactive PvP: 30–70ms | Balanced: 70–130ms | Stable PvE: 100–150ms"
L["Adaptive Jitter Margin"] = "Adaptive Jitter Margin"
L["Adaptive Jitter Margin Tooltip"] = "Widen the queue when your connection is unstable.\n\nFormula: margin = Safety Margin + (2 × jitter σ)\n\nJitter is measured from the last 25 world-latency samples (~12 minutes at steady ping). Needs 3+ samples before applying."

-- Chat
L["Update Message"] = "SQW set to %s (Ping: %d + Margin: %d [%d base + %d jitter])"

-- Diagnostics (/latencyguard status)
L["Status Unavailable"] = "Status is not available yet."
L["Status Header"] = "LatencyGuard status"
L["Status Version"] = "Version:"
L["Status Automation"] = "Automation:"
L["Status Verbose"] = "Chat feedback:"
L["Status Tolerance"] = "Safety margin:"
L["Status Adaptive Jitter"] = "Adaptive jitter:"
L["Status Jitter Margin"] = "Jitter margin:"
L["Status Jitter Warming"] = "Jitter warming:"
L["Status Effective Margin"] = "Effective margin:"
L["Status World Latency"] = "World latency:"
L["Status Home Latency"] = "Home latency:"
L["Status Current SQW"] = "Current spell queue:"
L["Status Target SQW"] = "Target spell queue:"
L["Status Delta"] = "Delta (current vs target):"
L["Status Raw Target"] = "Raw target (ping + margin):"
L["Status Clamp"] = "Clamped to range:"
L["Status Would Apply"] = "Would apply now:"
L["Status Pending"] = "Pending update:"
L["Status In Combat"] = "In combat:"
L["Status Ticker"] = "Ticker running:"
L["Status Discovery"] = "Latency discovery:"
