-- LatencyGuard: Dynamically adjusts SpellQueueWindow based on network latency
local _, LatencyGuard = ...
local L = LatencyGuard.L

-- Constants and Configuration
local UPDATE_INTERVAL = 10 -- Regular update interval in seconds
local ZERO_LATENCY_CHECK_INTERVAL = 5 -- Check interval when latency is zero
local MIN_LATENCY_THRESHOLD = 1 -- Minimum threshold value
local MAX_LATENCY_THRESHOLD = 50 -- Maximum threshold value (aligned with settings UI)
local MIN_SPELL_QUEUE_WINDOW = 0 -- Minimum SpellQueueWindow value
local MAX_SPELL_QUEUE_WINDOW = 400 -- Maximum SpellQueueWindow value (WoW client limit)
local DEFAULT_SPELL_QUEUE_WINDOW = 100 -- Fallback value if CVar read fails
local DEFAULT_MAX_LATENCY_CAP = 300 -- Default maximum latency cap

-- Cached WoW API functions for performance
local InCombatLockdown = InCombatLockdown
local GetNetStats = GetNetStats
local GetCVar = GetCVar
local SetCVar = SetCVar
local tonumber = tonumber
local math_max = math.max
local math_abs = math.abs
local math_min = math.min
local C_Timer = C_Timer

-- State Management
local isUpdateQueued = false
local zeroLatencyTicker = nil
local regularUpdateTicker = nil
local lastKnownLatency = 0
local consecutiveZeroLatencyCount = 0
local updateAttempts = 0
local maxUpdateAttempts = 3
local isInitializing = true

-- Settings cache (populated by option callbacks)
local latencyThreshold = MIN_LATENCY_THRESHOLD
local userWantsFeedback = false
local enableGuard = false
local enableDebugMode = false
local maxLatencyCap = DEFAULT_MAX_LATENCY_CAP

-- Utility Functions
local function debugPrint(...)
	if enableDebugMode and userWantsFeedback then
		LatencyGuard:Printf("[DEBUG] %s", string.format(...))
	end
end

local function validateLatencyThreshold(value)
	return math_max(MIN_LATENCY_THRESHOLD, math_min(MAX_LATENCY_THRESHOLD, value or MIN_LATENCY_THRESHOLD))
end

local function validateSpellQueueWindow(value)
	return math_max(MIN_SPELL_QUEUE_WINDOW, math_min(MAX_SPELL_QUEUE_WINDOW, value or DEFAULT_SPELL_QUEUE_WINDOW))
end

local function validateMaxLatencyCap(value)
	return math_max(100, math_min(MAX_SPELL_QUEUE_WINDOW, value or DEFAULT_MAX_LATENCY_CAP))
end

local function safeGetCVar(cvarName, defaultValue)
	local success, value = pcall(GetCVar, cvarName)
	if success and value then
		local numValue = tonumber(value)
		if numValue then
			debugPrint("Retrieved %s: %d", cvarName, numValue)
			return numValue
		end
	end
	debugPrint("Failed to retrieve %s, using default: %d", cvarName, defaultValue)
	return defaultValue
end

local function safeSetCVar(cvarName, value)
	if InCombatLockdown() then
		debugPrint("Cannot set %s during combat lockdown", cvarName)
		return false, "Cannot modify CVars during combat"
	end

	local success, err = pcall(SetCVar, cvarName, value)
	if not success then
		LatencyGuard:Printf("Failed to set %s: %s", cvarName, err or "Unknown error")
		return false, err
	end
	debugPrint("Successfully set %s to %d", cvarName, value)
	return true
end

-- Core Functionality
local function getCurrentLatency()
	local success, _, _, latencyHome, latencyWorld = pcall(GetNetStats)
	if not success or not latencyHome or not latencyWorld then
		debugPrint("Failed to retrieve network statistics")
		return nil, "Failed to retrieve network statistics"
	end

	-- Handle negative or invalid values
	latencyHome = math_max(0, latencyHome or 0)
	latencyWorld = math_max(0, latencyWorld or 0)

	local currentLatency = math_max(latencyHome, latencyWorld)
	debugPrint("Current latency: %d (Home: %d, World: %d)", currentLatency, latencyHome, latencyWorld)

	return currentLatency
end

local function updateSpellQueueWindow()
	-- Safety check: ensure addon is enabled
	if not enableGuard then
		debugPrint("LatencyGuard is disabled, skipping update")
		return false, "LatencyGuard is disabled"
	end

	-- Defer if in combat
	if InCombatLockdown() then
		isUpdateQueued = true
		debugPrint("Combat lockdown active, queuing update")
		return false, "Combat lockdown active - update queued"
	end

	-- Prevent excessive update attempts
	updateAttempts = updateAttempts + 1
	if updateAttempts > maxUpdateAttempts then
		LatencyGuard:Printf("Maximum update attempts (%d) reached, skipping update", maxUpdateAttempts)
		return false, "Maximum update attempts reached"
	end

	debugPrint("Starting update attempt %d/%d", updateAttempts, maxUpdateAttempts)

	-- Get current latency with error handling
	local currentLatency, latencyError = getCurrentLatency()
	if not currentLatency then
		LatencyGuard:Printf("Latency retrieval failed: %s", latencyError or "Unknown error")
		return false, latencyError
	end

	-- Handle zero latency case
	if currentLatency == 0 then
		consecutiveZeroLatencyCount = consecutiveZeroLatencyCount + 1
		debugPrint("Zero latency detected (count: %d)", consecutiveZeroLatencyCount)

		-- Start special handling for zero latency if not already active
		if not zeroLatencyTicker then
			if userWantsFeedback then
				LatencyGuard:Print(L["Zero latency detected, starting enhanced monitoring"])
			end
			zeroLatencyTicker = C_Timer.NewTicker(ZERO_LATENCY_CHECK_INTERVAL, updateSpellQueueWindow)
		end

		-- Don't update SpellQueueWindow for zero latency
		return false, "Zero latency detected"
	else
		-- Stop zero latency ticker if active
		if zeroLatencyTicker then
			zeroLatencyTicker:Cancel()
			zeroLatencyTicker = nil
			consecutiveZeroLatencyCount = 0
			debugPrint("Normal latency restored, stopping zero latency monitoring")
			if userWantsFeedback then
				LatencyGuard:Print(L["Normal latency restored, resuming standard monitoring"])
			end
		end
	end

	-- Apply maximum latency cap
	if currentLatency > maxLatencyCap then
		debugPrint("Latency (%d) exceeds cap (%d), capping value", currentLatency, maxLatencyCap)
		currentLatency = maxLatencyCap
	end

	-- Validate latency value
	currentLatency = validateSpellQueueWindow(currentLatency)

	-- Get current SpellQueueWindow setting
	local currentSpellQueueWindow = safeGetCVar("SpellQueueWindow", DEFAULT_SPELL_QUEUE_WINDOW)
	currentSpellQueueWindow = validateSpellQueueWindow(currentSpellQueueWindow)

	-- Check if update is needed based on threshold
	local latencyDifference = math_abs(currentSpellQueueWindow - currentLatency)
	debugPrint("Latency difference: %d (threshold: %d)", latencyDifference, latencyThreshold)

	if latencyDifference < latencyThreshold then
		debugPrint("Latency difference below threshold, no update needed")
		return false, "Latency difference below threshold"
	end

	-- Perform the update
	local success, error = safeSetCVar("SpellQueueWindow", currentLatency)
	if success then
		lastKnownLatency = currentLatency
		isUpdateQueued = false
		updateAttempts = 0 -- Reset on successful update

		if userWantsFeedback then
			LatencyGuard:Printf(L["SpellQueueWindow updated: %d -> %d (+%d)"], currentSpellQueueWindow, currentLatency, latencyDifference)
		end

		debugPrint("Update successful")
		return true, "Update successful"
	else
		debugPrint("Update failed: %s", error or "Unknown error")
		return false, error or "Update failed"
	end
end

-- Timer Management
local function startRegularUpdates()
	if regularUpdateTicker then
		regularUpdateTicker:Cancel()
	end

	if enableGuard then
		debugPrint("Starting regular updates every %d seconds", UPDATE_INTERVAL)
		regularUpdateTicker = C_Timer.NewTicker(UPDATE_INTERVAL, function()
			updateAttempts = 0 -- Reset attempts counter for each interval
			updateSpellQueueWindow()
		end)
	end
end

local function stopAllTimers()
	debugPrint("Stopping all timers")

	if regularUpdateTicker then
		regularUpdateTicker:Cancel()
		regularUpdateTicker = nil
	end

	if zeroLatencyTicker then
		zeroLatencyTicker:Cancel()
		zeroLatencyTicker = nil
	end
end

-- Event Handlers
function LatencyGuard:OnLogin()
	debugPrint("Player login detected")
	if enableGuard then
		-- Initial update after login
		updateSpellQueueWindow()
		startRegularUpdates()
	end
end

function LatencyGuard:PLAYER_REGEN_ENABLED()
	debugPrint("Player exited combat")
	if enableGuard and isUpdateQueued then
		-- Use Dashi's defer system for post-combat updates
		self:Defer(updateSpellQueueWindow)
	end
end

function LatencyGuard:CVAR_UPDATE(cvarName)
	-- Monitor SpellQueueWindow changes from other sources
	if cvarName == "SpellQueueWindow" and enableGuard then
		local newValue = safeGetCVar("SpellQueueWindow", DEFAULT_SPELL_QUEUE_WINDOW)
		debugPrint("SpellQueueWindow externally changed to: %d", newValue)

		if userWantsFeedback and math_abs(newValue - lastKnownLatency) > latencyThreshold then
			self:Printf(L["SpellQueueWindow externally modified to: %d"], newValue)
		end
	end
end

-- Option Callbacks (using Dashi's callback system)
LatencyGuard:RegisterOptionCallback("latencyThreshold", function(value)
	latencyThreshold = validateLatencyThreshold(value)
	debugPrint("Latency threshold updated to: %d", latencyThreshold)
	if userWantsFeedback and not isInitializing then
		LatencyGuard:Printf("Latency threshold updated to: %d", latencyThreshold)
	end
end)

LatencyGuard:RegisterOptionCallback("userWantsFeedback", function(value)
	userWantsFeedback = value or false
	debugPrint("Feedback messages %s", userWantsFeedback and "enabled" or "disabled")
	if userWantsFeedback and not isInitializing then
		LatencyGuard:Print("Feedback messages enabled")
	end
end)

LatencyGuard:RegisterOptionCallback("enableDebugMode", function(value)
	enableDebugMode = value or false
	if userWantsFeedback and not isInitializing then
		if enableDebugMode then
			LatencyGuard:Print(L["Debug mode enabled - expect verbose output"])
		else
			LatencyGuard:Print(L["Debug mode disabled"])
		end
	end
end)

LatencyGuard:RegisterOptionCallback("maxLatencyCap", function(value)
	maxLatencyCap = validateMaxLatencyCap(value)
	debugPrint("Maximum latency cap updated to: %d", maxLatencyCap)
	if userWantsFeedback and not isInitializing then
		LatencyGuard:Printf("Maximum latency cap set to: %d ms", maxLatencyCap)
	end
end)

LatencyGuard:RegisterOptionCallback("enableGuard", function(value)
	local wasEnabled = enableGuard
	enableGuard = value or false

	debugPrint("LatencyGuard %s", enableGuard and "enabled" or "disabled")

	if enableGuard and not wasEnabled then
		-- Enabling the addon
		startRegularUpdates()
		updateSpellQueueWindow()
		if userWantsFeedback and not isInitializing then
			LatencyGuard:Print(L["LatencyGuard enabled"])
		end
	elseif not enableGuard and wasEnabled then
		-- Disabling the addon
		stopAllTimers()
		isUpdateQueued = false
		if userWantsFeedback and not isInitializing then
			LatencyGuard:Print(L["LatencyGuard disabled"])
		end
	end
end)

-- Cleanup on addon unload
LatencyGuard:RegisterEvent("ADDON_LOADED", function(self, addonName)
	if addonName == "LatencyGuard" then
		debugPrint("LatencyGuard addon loaded")
		-- Mark initialization as complete after a brief delay to allow all settings to load
		C_Timer.After(1, function()
			isInitializing = false
		end)
		return true -- Unregister this event
	end
end)

-- Debug/Status Commands (can be extended)
LatencyGuard.GetStatus = function()
	local currentLatency = getCurrentLatency()
	local currentSpellQueueWindow = safeGetCVar("SpellQueueWindow", DEFAULT_SPELL_QUEUE_WINDOW)

	local status = {
		enabled = enableGuard,
		currentLatency = currentLatency,
		currentSpellQueueWindow = currentSpellQueueWindow,
		threshold = latencyThreshold,
		maxLatencyCap = maxLatencyCap,
		isUpdateQueued = isUpdateQueued,
		zeroLatencyActive = zeroLatencyTicker ~= nil,
		consecutiveZeroLatency = consecutiveZeroLatencyCount,
		debugMode = enableDebugMode,
		lastKnownLatency = lastKnownLatency,
	}

	debugPrint("Status: %s", status)
	return status
end
