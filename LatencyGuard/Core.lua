local ADDON_NAME, NS = ...
NS.Core = CreateFrame("Frame")
NS.Modules = {}

-- Cache Globals
local pairs = pairs
local print = print
local string_format = string.format
local C_AddOns_GetAddOnMetadata = C_AddOns.GetAddOnMetadata
local ipairs = ipairs

local DEFAULTS = {
	enabled = true,
	verbose = true,
	tolerance = 150,
}

-- Centralized Event Dispatcher (Research Pattern)
local registeredEvents = {}

function NS:RegisterEvent(event, callback)
	if not registeredEvents[event] then
		registeredEvents[event] = {}
		NS.Core:RegisterEvent(event)
	end
	-- Reuse tables where possible, avoid duplicate registrations
	for _, cb in ipairs(registeredEvents[event]) do
		if cb == callback then return end
	end
	registeredEvents[event][#registeredEvents[event] + 1] = callback
end

function NS:UnregisterEvent(event, callback)
	if registeredEvents[event] then
		for i = #registeredEvents[event], 1, -1 do
			if registeredEvents[event][i] == callback then
				table.remove(registeredEvents[event], i)
				break
			end
		end
		if #registeredEvents[event] == 0 then
			registeredEvents[event] = nil
			NS.Core:UnregisterEvent(event)
		end
	end
end

local function Core_OnEvent(self, event, ...)
	if event == "ADDON_LOADED" then
		local name = ...
		if name ~= ADDON_NAME then return end

		LatencyGuardDB = LatencyGuardDB or {}
		for k, v in pairs(DEFAULTS) do
			if LatencyGuardDB[k] == nil then
				LatencyGuardDB[k] = v
			end
		end
		
		-- Auto-initialize modules
		for _, module in pairs(NS.Modules) do
			if module.Init then module:Init() end
		end

		local version = C_AddOns_GetAddOnMetadata(ADDON_NAME, "Version") or "Unknown"
		if LatencyGuardDB.verbose then
			local L = NS.L
			NS.Utils:Print(string_format(L["Core_InitMessage"], version))
		end

		self:UnregisterEvent("ADDON_LOADED")
		return -- Skip dispatcher for ADDON_LOADED to avoid race conditions
	end

	-- Dispatch other events
	if registeredEvents[event] then
		for _, callback in ipairs(registeredEvents[event]) do
			callback(event, ...)
		end
	end
end

NS.Core:RegisterEvent("ADDON_LOADED")
NS.Core:SetScript("OnEvent", Core_OnEvent)

NS.Utils = {}
function NS.Utils:Print(msg)
	print(string_format("|cff00ccff%s:|r %s", ADDON_NAME, msg))
end

local function SlashCmdHandler()
	if NS.Modules.Config then
		NS.Modules.Config:Open()
	end
end

_G["SLASH_" .. ADDON_NAME .. "1"] = "/lg"
_G["SLASH_" .. ADDON_NAME .. "2"] = "/latencyguard"
SlashCmdList[ADDON_NAME] = SlashCmdHandler
