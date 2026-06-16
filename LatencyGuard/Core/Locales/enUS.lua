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
L["Open the options panel"] = "Open the options panel"

L["DESC_GENERAL"] = "Spell Queue Window tuning based on your live world latency."

-- Landing page
L["Landing Desc Title"] = "Why does this addon exist?"
L["Landing Desc Text"] = "The %s is a hidden game setting that controls the buffer time for your next ability.\n\n%s monitors your real-time world ping and adjusts this window automatically so your gameplay feels snappy without losing the ability to queue spells effectively. High latency requires a wider queue window, while low latency benefits from a tighter window.\n\nExpand the LatencyGuard menu on the left and open General to configure tolerance and feedback."

-- Module
L["Spell Queue"] = "Spell Queue"
L["Automate Spell Queue Window"] = "Automate Spell Queue Window"
L["Automate Spell Queue Window Tooltip"] = "When enabled, LatencyGuard manages all Spell Queue Window adjustments.\n\n|cffff0000Note:|r Disabling this stops all updates immediately."
L["Enable Chat Feedback"] = "Enable Chat Feedback"
L["Enable Chat Feedback Tooltip"] = "Print a message in chat whenever the Spell Queue Window is updated with a new target value."
L["Tolerance Buffer"] = "Tolerance Buffer"
L["Tolerance Buffer Tooltip"] = "This value is added to your current world ping.\n\nHigh values (200+) are safer for high-latency connections.\nLow values (50-100) are better for high-end competitive play."

-- Chat
L["Init Message"] = "v%s initialized. Use |cFFFFD700/lg|r to configure."
L["Update Message"] = "SQW set to |cFFFFD700%dms|r (Ping: %d + Buffer: %d)"
