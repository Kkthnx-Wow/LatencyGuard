-- Settings registration for LatencyGuard.
-- Uses Dashi's settings API; titles/tooltips are localized via L.
local _, LatencyGuard = ...
local L = LatencyGuard.L

LatencyGuard:RegisterSettings("LatencyGuardDB", {
	{
		key = "enableGuard",
		type = "toggle",
		title = L["Enable Latency Guard"],
		tooltip = L["Enable or disable the LatencyGuard functionality.|n|nWhen enabled, automatically adjusts SpellQueueWindow based on your network latency for optimal spell casting performance."],
		default = true,
	},
	{
		key = "userWantsFeedback",
		type = "toggle",
		title = L["Enable Feedback Messages"],
		tooltip = L["Show chat messages when SpellQueueWindow is updated.|n|nHelps you monitor the addon's activity and understand when adjustments are made."],
		default = false,
		requires = "enableGuard",
	},
	{
		key = "latencyThreshold",
		type = "slider",
		title = L["Latency Threshold"],
		tooltip = L["The minimum change in latency (in milliseconds) required to update the SpellQueueWindow.|n|nLower values = more frequent updates|nHigher values = fewer, larger adjustments|n|nRecommended: 1-5ms for responsive gameplay, 10-20ms for stable connections."],
		default = 1,
		minValue = 1,
		maxValue = 50,
		valueStep = 1,
		valueFormat = "%d ms",
		requires = "enableGuard",
	},
	{
		key = "enableDebugMode",
		type = "toggle",
		title = L["Debug Mode"],
		tooltip = L["Enable detailed debug information in chat.|n|nWarning: This will generate many chat messages and should only be used for troubleshooting."],
		default = false,
		requires = "enableGuard",
	},
	{
		key = "maxLatencyCap",
		type = "slider",
		title = L["Maximum Latency Cap"],
		tooltip = L["Maximum allowed SpellQueueWindow value (in milliseconds).|n|nPrevents extremely high latency spikes from setting unreasonable values.|n|nRecommended: 200-400ms depending on your connection stability."],
		default = 300,
		minValue = 100,
		maxValue = 400,
		valueStep = 10,
		valueFormat = "%d ms",
		requires = "enableGuard",
	},
})

LatencyGuard:RegisterSettingsSlash("/lg", "/latencyguard")
