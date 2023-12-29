LatencyGuardLocalization = {}
local L = LatencyGuardLocalization

local locale = GetLocale()

-- English (default language)
L["LatencyGuard Configuration"] = "LatencyGuard Configuration"
L["Customize the behavior of LatencyGuard."] = "Customize the behavior of LatencyGuard"
L["Enable LatencyGuard"] = "Enable LatencyGuard"
L["Enable Feedback Messages"] = "Enable Feedback Messages"
L["Latency Threshold: 10"] = "Latency Threshold: 10"
L["Latency Threshold: "] = "Latency Threshold: "
L["Latency Threshold"] = "Latency Threshold"
L["Adjust this value to set the latency threshold for your addon."] = "Adjust this value to set the latency threshold for your addon"

-- German (deDE)
if locale == "deDE" then
	-- Add German translations here
	-- L["LatencyGuard Configuration"] = "German Translation"
	-- ...
end

-- French (frFR)
if locale == "frFR" then
	-- Add French translations here
	-- L["LatencyGuard Configuration"] = "French Translation"
	-- ...
end

-- Add additional languages following the same pattern

-- Function to handle localization
function GetLocalization(string)
	return L[string] or string
end

-- Usage
-- local text = GetLocalization("LatencyGuard Configuration")
