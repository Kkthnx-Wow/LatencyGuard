local ADDON_NAME, NS = ...
NS.Modules.Logic = {}
local Module = NS.Modules.Logic

-- Cache Globals
local GetNetStats = GetNetStats
local GetCVar = GetCVar
local SetCVar = SetCVar
local InCombatLockdown = InCombatLockdown
local C_Timer = C_Timer
local math_max = math.max
local math_abs = math.abs
local tonumber = tonumber
local string_format = string.format

-- Secret Values (Midnight 12.0+). `issecretvalue` only exists on Midnight clients;
-- the TOC also targets older flavors, so fall back to a no-op that reports "not secret".
local issecretvalue = issecretvalue or function() return false end

-- Constants
local TICK_RATE_STEADY = 30
local TICK_RATE_DISCOVERY = 2
local MIN_QUEUE_WINDOW = 100
local MAX_QUEUE_WINDOW = 400
local HYSTERESIS = 40

-- State
Module.pendingUpdate = false
Module.discoveryActive = false

local function DiscoveryTimerCallback()
	Module.discoveryActive = false
	Module:UpdateQueueWindow()
end

function Module:UpdateQueueWindow()
	if not LatencyGuardDB.enabled then return end

	local _, _, _, latencyWorld = GetNetStats()

	-- GetNetStats is network telemetry, not combat data, so Blizzard does not
	-- secret it. Guard anyway: comparing/adding a Secret throws a Lua error, and
	-- we'd rather skip a cycle than break if the API is ever secreted.
	if issecretvalue(latencyWorld) then return end

	if not latencyWorld or latencyWorld <= 0 then
		if not self.discoveryActive then
			self.discoveryActive = true
			C_Timer.After(TICK_RATE_DISCOVERY, DiscoveryTimerCallback)
		end
		return
	end

	if InCombatLockdown() then
		self.pendingUpdate = true
		return
	end

	local target = latencyWorld + LatencyGuardDB.tolerance
	target = math_max(MIN_QUEUE_WINDOW, target)
	if target > MAX_QUEUE_WINDOW then
		target = MAX_QUEUE_WINDOW
	end

	local current = tonumber(GetCVar("SpellQueueWindow")) or 400

	if math_abs(current - target) >= HYSTERESIS then
		SetCVar("SpellQueueWindow", target)
		self.pendingUpdate = false

		if LatencyGuardDB.verbose then
			local L = NS.L
			NS.Utils:Print(string_format(L["Logic_UpdateMessage"], target, latencyWorld, LatencyGuardDB.tolerance))
		end
	end
end

local function SteadyTickerCallback()
	Module:UpdateQueueWindow()
end

local function OnRegenEnabled()
	if Module.pendingUpdate then
		Module:UpdateQueueWindow()
	end
end

function Module:Init()
	-- Create the maintenance ticker
	C_Timer.NewTicker(TICK_RATE_STEADY, SteadyTickerCallback)
	
	-- Register Events
	NS:RegisterEvent("PLAYER_REGEN_ENABLED", OnRegenEnabled)

	-- Initial Run
	self:UpdateQueueWindow()
end
