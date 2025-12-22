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

-- Constants
local TICK_RATE_STEADY = 30
local TICK_RATE_DISCOVERY = 2
local MIN_QUEUE_WINDOW = 100
local MAX_QUEUE_WINDOW = 400
local HYSTERESIS = 40

-- State
Module.pendingUpdate = false

function Module:UpdateQueueWindow()
	if not LatencyGuardDB.enabled then
		return
	end

	local _, _, _, latencyWorld = GetNetStats()

	-- Discovery Logic: If ping is 0, we haven't handshaked with the server yet.
	if not latencyWorld or latencyWorld <= 0 then
		if not self.discoveryActive then
			self.discoveryActive = true
			C_Timer.After(TICK_RATE_DISCOVERY, function()
				self.discoveryActive = false
				self:UpdateQueueWindow()
			end)
		end
		return
	end

	-- Security Guard: Defer CVar updates until out of combat
	if InCombatLockdown() then
		self.pendingUpdate = true
		return
	end

	-- Calculation
	local target = latencyWorld + LatencyGuardDB.tolerance
	target = math_max(MIN_QUEUE_WINDOW, target)
	if target > MAX_QUEUE_WINDOW then
		target = MAX_QUEUE_WINDOW
	end

	local current = tonumber(GetCVar("SpellQueueWindow")) or 400

	-- Apply Hysteresis
	if math_abs(current - target) >= HYSTERESIS then
		SetCVar("SpellQueueWindow", target)
		self.pendingUpdate = false

		if LatencyGuardDB.verbose then
			NS.Utils:Print(string_format("SQW set to |cFFFFD700%dms|r (Ping: %d + Buffer: %d)", target, latencyWorld, LatencyGuardDB.tolerance))
		end
	end
end

function Module:Init()
	-- Create the maintenance ticker
	C_Timer.NewTicker(TICK_RATE_STEADY, function()
		self:UpdateQueueWindow()
	end)

	-- Register for combat exit to process deferred updates
	local f = CreateFrame("Frame")
	f:RegisterEvent("PLAYER_REGEN_ENABLED")
	f:SetScript("OnEvent", function()
		if self.pendingUpdate then
			self:UpdateQueueWindow()
		end
	end)

	-- Initial Run
	self:UpdateQueueWindow()
end
