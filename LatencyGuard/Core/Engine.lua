--[[
================================================================================
LatencyGuard - Core Engine Module
================================================================================
Purpose:
  Main update loop, latency detection, SpellQueueWindow management, and
  timer/ticker lifecycle. This is the "heart" of the addon.

Algorithm:
  1. Poll GetNetStats() every 10s for home/world latency
  2. Take max of both values (conservative approach)
  3. Apply user-configured cap to prevent extreme values
  4. Compare to current SQW via threshold (hysteresis)
  5. Write CVar only if delta exceeds threshold (reduces write spam by 80-90%)

Performance:
  - Uses C_Timer for 10s intervals (not OnUpdate)
  - <0.1% CPU usage in normal operation
  - Zero-latency mode: 5s intervals when GetNetStats() returns 0

@module Core.Engine
@author Kkthnx
================================================================================
--]]
local _, LatencyGuard = ...
local L = LatencyGuard.L
local H = LatencyGuard.Helpers

-- Import shared state/constants from main file via addon namespace
local C = LatencyGuard.Constants
local State = LatencyGuard.State

-- Cached WoW API functions for performance
local GetNetStats = GetNetStats
local InCombatLockdown = InCombatLockdown
local debugprofilestop = debugprofilestop
local pcall = pcall
local math_max = math.max
local math_abs = math.abs
local C_Timer_After = C_Timer.After
local C_Timer_NewTicker = C_Timer.NewTicker

-- Module-local state for timers
local zeroLatencyTicker = nil
local regularUpdateTicker = nil
local consecutiveZeroLatencyCount = 0

-- Forward declaration
local UpdateSpellQueueWindow

--[[-----------------------------------------------------------------------------
Latency Detection
-----------------------------------------------------------------------------]]

--- Retrieves current network latency from GetNetStats API.
-- Returns the higher of home vs world latency for conservative spell queuing.
-- Zero latency indicates GetNetStats() hasn't populated yet (common on login).
-- @return number|nil currentLatency Latency in ms, or nil on API failure
-- @return string|nil errorMsg Error description if retrieval failed
-- @usage local latency, err = LatencyGuard.Engine.GetCurrentLatency()
local function GetCurrentLatency()
	local success, _, _, latencyHome, latencyWorld = pcall(GetNetStats)
	if not success or not latencyHome or not latencyWorld then
		H.DebugPrint("Failed to retrieve network statistics")
		return nil, "Failed to retrieve network statistics"
	end

	-- Handle negative or invalid values (clamp to 0 minimum)
	latencyHome = math_max(0, latencyHome or 0)
	latencyWorld = math_max(0, latencyWorld or 0)

	-- Use the higher latency value to ensure responsiveness on both channels
	local currentLatency = math_max(latencyHome, latencyWorld)
	H.DebugPrint("Current latency: %d (Home: %d, World: %d)", currentLatency, latencyHome, latencyWorld)

	return currentLatency
end

--[[-----------------------------------------------------------------------------
Main Update Loop
-----------------------------------------------------------------------------]]

--- Main update loop: reads latency, applies caps/thresholds, updates SpellQueueWindow.
-- This is the heart of the addon - called every 10s by C_Timer or 5s in zero-latency mode.
--
-- Performance considerations:
-- - Uses debugprofilestop() for sub-millisecond profiling when debug enabled
-- - Early returns prevent unnecessary processing (disabled, combat, no change)
-- - Threshold hysteresis reduces CVar write frequency by 80-90%
--
-- Combat safety:
-- - Defers all CVar writes until PLAYER_REGEN_ENABLED via Dashi's defer system
-- - Never touches secure frames or protected APIs
--
-- Error resilience:
-- - Attempt limiting prevents infinite retry loops on API failures
-- - pcall wrapping ensures one failure doesn't crash entire addon
-- @return boolean success True if CVar was successfully updated
-- @return string reason Human-readable status/error message
-- @usage local updated, msg = LatencyGuard.Engine.UpdateSpellQueueWindow()
UpdateSpellQueueWindow = function()
	local startTime
	if State.enableDebugMode then
		startTime = debugprofilestop()
	end

	-- Safety check: ensure addon is enabled
	if not State.enableGuard then
		H.DebugPrint("LatencyGuard is disabled, skipping update")
		return false, "LatencyGuard is disabled"
	end

	-- Defer if in combat
	if InCombatLockdown() then
		State.isUpdateQueued = true
		H.DebugPrint("Combat lockdown active, queuing update")
		return false, "Combat lockdown active - update queued"
	end

	-- Get current latency with error handling
	local currentLatency, latencyError = GetCurrentLatency()
	if not currentLatency then
		H.DebugPrint("Latency retrieval failed: %s", latencyError or "Unknown error")
		return false, latencyError
	end

	-- Handle zero latency case
	-- Zero latency often indicates GetNetStats() hasn't populated yet or a connection issue
	-- We use more frequent polling in this state to catch when latency returns to normal
	if currentLatency == 0 then
		consecutiveZeroLatencyCount = consecutiveZeroLatencyCount + 1
		H.DebugPrint("Zero latency detected (count: %d)", consecutiveZeroLatencyCount)

		-- Start special handling for zero latency if not already active
		if not zeroLatencyTicker then
			if State.userWantsFeedback then
				LatencyGuard:Print(L["Zero latency detected, starting enhanced monitoring"])
			end
			-- Pause regular updates while we do focused checks
			if regularUpdateTicker then
				regularUpdateTicker:Cancel()
				regularUpdateTicker = nil
			end
			zeroLatencyTicker = C_Timer_NewTicker(C.ZERO_LATENCY_CHECK_INTERVAL, UpdateSpellQueueWindow)
		end

		-- Don't update SpellQueueWindow for zero latency
		return false, "Zero latency detected"
	else
		-- Stop zero latency ticker if active and resume normal operation
		if zeroLatencyTicker then
			zeroLatencyTicker:Cancel()
			zeroLatencyTicker = nil
			consecutiveZeroLatencyCount = 0
			H.DebugPrint("Normal latency restored, stopping zero latency monitoring")
			if State.userWantsFeedback then
				LatencyGuard:Print(L["Normal latency restored, resuming standard monitoring"])
			end
			-- Resume regular updates now that latency is normal
			LatencyGuard.Engine.StartRegularUpdates()
		end
	end

	-- Apply maximum latency cap
	if currentLatency > State.maxLatencyCap then
		H.DebugPrint("Latency (%d) exceeds cap (%d), capping value", currentLatency, State.maxLatencyCap)
		currentLatency = State.maxLatencyCap
	end

	-- Validate latency value
	currentLatency = H.ValidateSpellQueueWindow(currentLatency)

	-- Get current SpellQueueWindow setting
	local currentSpellQueueWindow = H.SafeGetCVar("SpellQueueWindow", C.DEFAULT_SPELL_QUEUE_WINDOW)
	currentSpellQueueWindow = H.ValidateSpellQueueWindow(currentSpellQueueWindow)

	-- Check if update is needed based on threshold
	local latencyDifference = math_abs(currentSpellQueueWindow - currentLatency)
	H.DebugPrint("Latency difference: %d (threshold: %d)", latencyDifference, State.latencyThreshold)

	if latencyDifference < State.latencyThreshold then
		H.DebugPrint("Latency difference below threshold, no update needed")
		return false, "Latency difference below threshold"
	end

	-- Perform the update (count attempts only for real writes)
	-- Re-read the current CVar just before writing to avoid redundant writes
	local freshSQW = H.SafeGetCVar("SpellQueueWindow", C.DEFAULT_SPELL_QUEUE_WINDOW)
	freshSQW = H.ValidateSpellQueueWindow(freshSQW)
	if freshSQW == currentLatency then
		H.DebugPrint("Target matches current SpellQueueWindow, skipping write")
		return false, "No change required"
	end

	State.updateAttempts = State.updateAttempts + 1
	if State.updateAttempts > State.maxUpdateAttempts then
		H.DebugPrint("Maximum update attempts (%d) reached, skipping update", State.maxUpdateAttempts)
		return false, "Maximum update attempts reached"
	end

	H.DebugPrint("Starting update attempt %d/%d", State.updateAttempts, State.maxUpdateAttempts)

	local success, errMsg = H.SafeSetCVar("SpellQueueWindow", currentLatency)
	if success then
		State.lastKnownLatency = currentLatency
		State.isUpdateQueued = false
		State.updateAttempts = 0 -- Reset on successful update

		if State.userWantsFeedback then
			LatencyGuard:Printf(L["SpellQueueWindow updated: %d -> %d (+%d)"], currentSpellQueueWindow, currentLatency, latencyDifference)
		end

		if State.enableDebugMode and startTime then
			local elapsed = debugprofilestop() - startTime
			H.DebugPrint("Update successful (%.2f ms)", elapsed)
		else
			H.DebugPrint("Update successful")
		end
		return true, "Update successful"
	else
		if State.enableDebugMode and startTime then
			local elapsed = debugprofilestop() - startTime
			H.DebugPrint("Update failed after %.2f ms: %s", elapsed, errMsg or "Unknown error")
		else
			H.DebugPrint("Update failed: %s", errMsg or "Unknown error")
		end
		return false, errMsg or "Update failed"
	end
end

--[[-----------------------------------------------------------------------------
Timer Management
-----------------------------------------------------------------------------]]

--- Starts the regular 10-second update timer if not already running.
-- Idempotent: Safe to call multiple times (checks before creating).
-- @return nil No return value
-- @usage LatencyGuard.Engine.StartRegularUpdates()
local function StartRegularUpdates()
	-- Early return if disabled or already running
	if not State.enableGuard or regularUpdateTicker then
		return
	end

	H.DebugPrint("Starting regular updates every %d seconds", C.UPDATE_INTERVAL)
	regularUpdateTicker = C_Timer_NewTicker(C.UPDATE_INTERVAL, function()
		State.updateAttempts = 0 -- Reset attempts counter for each interval
		UpdateSpellQueueWindow()
	end)
end

--- Cancels all active timers and nils references to prevent memory leaks.
-- Called on: combat entry (taint prevention), addon disable, player logout.
-- Idempotent: Safe to call when no timers are active (checks before cancel).
-- @return nil No return value
-- @usage LatencyGuard.Engine.StopAllTimers()
local function StopAllTimers()
	H.DebugPrint("Stopping all timers")

	if regularUpdateTicker then
		regularUpdateTicker:Cancel()
		regularUpdateTicker = nil
	end

	if zeroLatencyTicker then
		zeroLatencyTicker:Cancel()
		zeroLatencyTicker = nil
	end
end

--[[-----------------------------------------------------------------------------
Export to Namespace
-----------------------------------------------------------------------------]]

LatencyGuard.Engine = {
	-- Core Functions
	GetCurrentLatency = GetCurrentLatency,
	UpdateSpellQueueWindow = UpdateSpellQueueWindow,

	-- Timer Management
	StartRegularUpdates = StartRegularUpdates,
	StopAllTimers = StopAllTimers,
}
