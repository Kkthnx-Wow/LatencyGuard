--[[
================================================================================
LatencyGuard - Slash Commands & Debug Tools Module
================================================================================
Purpose:
  Diagnostic slash commands, status reporting, and debug utilities for
  troubleshooting and monitoring addon performance in production.

Commands:
  - /lgstatus, /lgstat, /lgstats, /lginfo: Print full status to chat
  - /lgdebug [on|off]: Toggle debug mode dynamically

Design:
  - Reuses statusTable via wipe() for zero-allocation GetStatus()
  - Direct field access instead of pairs() iteration for performance

@module Core.Commands
@author Kkthnx
================================================================================
--]]
local _, LatencyGuard = ...
local L = LatencyGuard.L
local H = LatencyGuard.Helpers
local Engine = LatencyGuard.Engine

-- Import shared state/constants from main file via addon namespace
local C = LatencyGuard.Constants
local State = LatencyGuard.State

-- Cached functions for performance
local tostring = tostring
local string_lower = string.lower
local table_wipe = wipe

-- Reusable table for GetStatus (memory optimization)
local statusTable = {}

--[[-----------------------------------------------------------------------------
Status Reporting
-----------------------------------------------------------------------------]]

--- Retrieves current addon status as a table.
-- Reuses statusTable via wipe() to avoid allocations on every call.
-- @return table statusTable Status fields (enabled, currentLatency, etc.)
-- @usage local status = LatencyGuard.GetStatus()
function LatencyGuard.GetStatus()
	local currentLatency = Engine.GetCurrentLatency()
	local currentSpellQueueWindow = H.SafeGetCVar("SpellQueueWindow", C.DEFAULT_SPELL_QUEUE_WINDOW)

	-- Reuse table to avoid allocations
	table_wipe(statusTable)
	statusTable.enabled = State.enableGuard
	statusTable.currentLatency = currentLatency
	statusTable.currentSpellQueueWindow = currentSpellQueueWindow
	statusTable.threshold = State.latencyThreshold
	statusTable.maxLatencyCap = State.maxLatencyCap
	statusTable.isUpdateQueued = State.isUpdateQueued
	statusTable.zeroLatencyActive = false -- NOTE: zeroLatencyTicker is module-local in Engine
	statusTable.consecutiveZeroLatency = 0 -- NOTE: consecutiveZeroLatencyCount is module-local in Engine
	statusTable.debugMode = State.enableDebugMode
	statusTable.lastKnownLatency = State.lastKnownLatency

	return statusTable
end

--[[-----------------------------------------------------------------------------
Slash Commands
-----------------------------------------------------------------------------]]

--- /lgstatus command: Prints detailed addon status to chat.
-- Shows all diagnostic info: enabled state, current latency, SQW, thresholds, etc.
LatencyGuard:RegisterSlash("/lgstatus", "/lgstat", "/lgstats", "/lginfo", function()
	local status = LatencyGuard.GetStatus()
	-- Direct iteration without creating intermediate arrays
	LatencyGuard:Print("=== LatencyGuard Status ===")
	LatencyGuard:Printf("Enabled: %s", tostring(status.enabled))
	LatencyGuard:Printf("Current Latency: %s", tostring(status.currentLatency))
	LatencyGuard:Printf("Current SQW: %s", tostring(status.currentSpellQueueWindow))
	LatencyGuard:Printf("Threshold: %s", tostring(status.threshold))
	LatencyGuard:Printf("Max Latency Cap: %s", tostring(status.maxLatencyCap))
	LatencyGuard:Printf("Update Queued: %s", tostring(status.isUpdateQueued))
	LatencyGuard:Printf("Debug Mode: %s", tostring(status.debugMode))
	LatencyGuard:Printf("Last Known Latency: %s", tostring(status.lastKnownLatency))
end)

--- /lgdebug command: Toggle debug mode dynamically without opening settings UI.
-- Auto-enables feedback if enabling debug (debug without feedback shows nothing).
-- @param input string User input: "on", "off", "1", "true", etc.
LatencyGuard:RegisterSlash("/lgdebug", function(input)
	input = string_lower(tostring(input or ""))
	local enable = (input == "on" or input == "1" or input == "true")
	LatencyGuard:TriggerOptionCallback("enableDebugMode", enable)
	if enable and not State.userWantsFeedback then
		LatencyGuard:TriggerOptionCallback("userWantsFeedback", true)
	end
	if enable then
		LatencyGuard:Print(L["Debug mode enabled - expect verbose output"])
	else
		LatencyGuard:Print(L["Debug mode disabled"])
	end
end)

--[[-----------------------------------------------------------------------------
Module Exports
-----------------------------------------------------------------------------]]

-- Export GetStatus for external addons/weakauras
LatencyGuard.Commands = {
	GetStatus = LatencyGuard.GetStatus,
}
