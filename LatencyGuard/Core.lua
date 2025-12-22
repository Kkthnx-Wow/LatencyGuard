local ADDON_NAME, NS = ...
NS.Core = CreateFrame("Frame")
NS.Modules = {}

-- Cache Globals
local string_format = string.format

local DEFAULTS = {
	enabled = true,
	verbose = true,
	tolerance = 150,
}

NS.Core:RegisterEvent("ADDON_LOADED")
NS.Core:RegisterEvent("PLAYER_LOGIN")

NS.Core:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local name = ...
		if name ~= ADDON_NAME then
			return
		end

		LatencyGuardDB = LatencyGuardDB or {}
		for k, v in pairs(DEFAULTS) do
			if LatencyGuardDB[k] == nil then
				LatencyGuardDB[k] = v
			end
		end
		self:UnregisterEvent("ADDON_LOADED")
	elseif event == "PLAYER_LOGIN" then
		if NS.Modules.Logic then
			NS.Modules.Logic:Init()
		end
		if NS.Modules.Config then
			NS.Modules.Config:Init()
		end

		if LatencyGuardDB.verbose then
			NS.Utils:Print("Initialized. Use |cFFFFD700/lg|r to configure.")
		end
	end
end)

NS.Utils = {}
function NS.Utils:Print(msg)
	print(string_format("|cff00ccff%s:|r %s", ADDON_NAME, msg))
end

_G["SLASH_LATENCYGUARD1"] = "/lg"
_G["SLASH_LATENCYGUARD2"] = "/latencyguard"
SlashCmdList["LATENCYGUARD"] = function()
	if NS.Modules.Config then
		NS.Modules.Config:Open()
	end
end
