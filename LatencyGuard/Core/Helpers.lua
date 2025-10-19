--[[
================================================================================
LatencyGuard - Helper Utilities Module
================================================================================
Purpose:
  Validation functions, safe API wrappers, and utility functions for the
  LatencyGuard addon. All functions in this module are pure (no side effects
  except logging) and can be called from any other module.

Why separate:
  - Reusable across multiple modules
  - Easy to unit test (pure functions)
  - Reduces coupling between modules
  - Follows single-responsibility principle

@module Core.Helpers
@author Kkthnx
================================================================================
--]]
local _, LatencyGuard = ...

-- Import shared state/constants from main file via addon namespace
local C = LatencyGuard.Constants
local State = LatencyGuard.State

-- Cached WoW API functions for performance
local GetCVar = GetCVar
local SetCVar = SetCVar
local InCombatLockdown = InCombatLockdown
local pcall = pcall
local select = select
local type = type
local string_format = string.format
local tostring = tostring
local table_concat = table.concat
local table_wipe = wipe
local tonumber = tonumber
local math_max = math.max
local math_abs = math.abs
local math_min = math.min

-- Reusable buffer for debug printing (memory optimization)
local debugPrintBuffer = {}

--[[-----------------------------------------------------------------------------
Debug Logging
-----------------------------------------------------------------------------]]

--- Gated debug logger that only prints when debug mode AND feedback enabled.
-- Prevents chat spam in production while allowing detailed troubleshooting.
-- Uses table pooling for fallback string concatenation to avoid GC pressure.
-- @param fmt string|any Format string (or single value if not string)
-- @param ... vararg Additional format arguments
-- @return nil No return value (side-effect only: chat output)
-- @usage LatencyGuard.Helpers.DebugPrint("Latency: %d ms", 42)
local function DebugPrint(fmt, ...)
	if not (State.enableDebugMode and State.userWantsFeedback) then
		return
	end

	if type(fmt) ~= "string" then
		LatencyGuard:Printf("[DEBUG] %s", tostring(fmt))
		return
	end

	local ok, msg = pcall(string_format, fmt, ...)
	if ok then
		LatencyGuard:Printf("[DEBUG] %s", msg)
	else
		-- Fallback: stringify args without formatting to avoid runtime errors
		-- Reuse table to avoid allocations
		table_wipe(debugPrintBuffer)
		debugPrintBuffer[1] = fmt
		local n = select("#", ...)
		for i = 1, n do
			debugPrintBuffer[i + 1] = tostring(select(i, ...))
		end
		LatencyGuard:Printf("[DEBUG] %s", table_concat(debugPrintBuffer, " "))
	end
end

--[[-----------------------------------------------------------------------------
Validation Functions
-----------------------------------------------------------------------------]]

--- Validates and clamps latency threshold to safe bounds.
-- Prevents users from setting invalid values via settings UI that could
-- cause excessive CVar writes (too low) or unresponsiveness (too high).
-- @param value number|nil User-provided threshold value
-- @return number Clamped value in range [MIN_LATENCY_THRESHOLD, MAX_LATENCY_THRESHOLD]
-- @usage local threshold = LatencyGuard.Helpers.ValidateLatencyThreshold(userInput)
local function ValidateLatencyThreshold(value)
	return math_max(C.MIN_LATENCY_THRESHOLD, math_min(C.MAX_LATENCY_THRESHOLD, value or C.MIN_LATENCY_THRESHOLD))
end

--- Validates and clamps SpellQueueWindow value to WoW's acceptable range.
-- Prevents crashes or unexpected behavior from out-of-bounds CVar writes.
-- WoW client enforces MAX_SPELL_QUEUE_WINDOW = 400ms internally.
-- @param value number|nil Value to validate (typically from GetCVar or latency)
-- @return number Clamped value in range [0, 400]
-- @usage local sqw = LatencyGuard.Helpers.ValidateSpellQueueWindow(latency)
local function ValidateSpellQueueWindow(value)
	return math_max(C.MIN_SPELL_QUEUE_WINDOW, math_min(C.MAX_SPELL_QUEUE_WINDOW, value or C.DEFAULT_SPELL_QUEUE_WINDOW))
end

--- Validates and clamps maximum latency cap to reasonable bounds.
-- Prevents extreme caps that could make gameplay unplayable or allow
-- unrealistic SQW values during lag spikes.
-- @param value number|nil User-configured cap value
-- @return number Clamped value in range [100, 400]
-- @usage local cap = LatencyGuard.Helpers.ValidateMaxLatencyCap(settings.maxLatencyCap)
local function ValidateMaxLatencyCap(value)
	return math_max(100, math_min(C.MAX_SPELL_QUEUE_WINDOW, value or C.DEFAULT_MAX_LATENCY_CAP))
end

--[[-----------------------------------------------------------------------------
Safe API Wrappers
-----------------------------------------------------------------------------]]

--- Safely retrieves a numeric CVar value with fallback and error handling.
-- Wraps GetCVar in pcall to prevent UI errors if CVar doesn't exist or
-- returns invalid data. Logs failures in debug mode for troubleshooting.
-- @param cvarName string Name of the CVar to retrieve (e.g., "SpellQueueWindow")
-- @param defaultValue number Fallback value if CVar read fails
-- @return number The CVar value as number, or defaultValue on failure
-- @usage local sqw = LatencyGuard.Helpers.SafeGetCVar("SpellQueueWindow", 100)
local function SafeGetCVar(cvarName, defaultValue)
	local success, value = pcall(GetCVar, cvarName)
	if success and value then
		local numValue = tonumber(value)
		if numValue then
			DebugPrint("Retrieved %s: %d", cvarName, numValue)
			return numValue
		end
	end
	DebugPrint("Failed to retrieve %s, using default: %d", cvarName, defaultValue)
	return defaultValue
end

--- Safely sets a CVar value, deferring writes during combat lockdown.
-- CRITICAL: Never writes CVars in combat to prevent taint. Defers via
-- Dashi's system for post-combat execution. Wraps SetCVar in pcall to
-- handle API errors gracefully (e.g., if CVar becomes protected mid-patch).
-- @param cvarName string Name of the CVar to set (e.g., "SpellQueueWindow")
-- @param value number Value to write (should be pre-validated)
-- @return boolean success True if write succeeded immediately
-- @return string|nil reason Error message if failed, or "Deferred until after combat"
-- @usage local ok, err = LatencyGuard.Helpers.SafeSetCVar("SpellQueueWindow", 150)
local function SafeSetCVar(cvarName, value)
	if InCombatLockdown() then
		DebugPrint("Cannot set %s during combat lockdown", cvarName)
		-- Ensure we never change CVars in combat; defer safely until after combat ends
		State.isUpdateQueued = true
		LatencyGuard:Defer(SetCVar, cvarName, value)
		return false, "Deferred until after combat"
	end

	local success, err = pcall(SetCVar, cvarName, value)
	if not success then
		LatencyGuard:Printf("Failed to set %s: %s", cvarName, err or "Unknown error")
		return false, err
	end
	DebugPrint("Successfully set %s to %d", cvarName, value)
	return true
end

--[[-----------------------------------------------------------------------------
Export to Namespace
-----------------------------------------------------------------------------]]

LatencyGuard.Helpers = {
	-- Debug
	DebugPrint = DebugPrint,

	-- Validation
	ValidateLatencyThreshold = ValidateLatencyThreshold,
	ValidateSpellQueueWindow = ValidateSpellQueueWindow,
	ValidateMaxLatencyCap = ValidateMaxLatencyCap,

	-- Safe API Wrappers
	SafeGetCVar = SafeGetCVar,
	SafeSetCVar = SafeSetCVar,
}
