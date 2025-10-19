--[[
================================================================================
LatencyGuard - Event Handlers Module
================================================================================
Purpose:
  All WoW event handlers for responding to game state changes (combat, login,
  zone changes, CVar modifications, settings callbacks).

Event Strategy:
  - Register only essential events to minimize overhead
  - Unregister one-time events after firing (return true)
  - Check State.enableGuard before processing to respect user disable

Combat Lockdown Pattern:
  - PLAYER_REGEN_DISABLED: Stop timers, queue pending update
  - PLAYER_REGEN_ENABLED: Restart timers, process queued update
  - Why: Prevents tainted CVar writes that block protected actions

@module Core.Events
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

-- Cached WoW API functions for performance
local InCombatLockdown = InCombatLockdown
local tostring = tostring
local math_abs = math.abs
local C_Timer_After = C_Timer.After

--[[-----------------------------------------------------------------------------
Lifecycle Event Handlers
-----------------------------------------------------------------------------]]

--- OnLogin stub handler (scheduling done in PLAYER_ENTERING_WORLD).
-- Exists for Dashi framework compatibility but primary init is delayed.
-- @param self table LatencyGuard addon object
-- @return nil No return value
function LatencyGuard:OnLogin()
	H.DebugPrint("Player login detected")
	-- Scheduling handled in PLAYER_ENTERING_WORLD for granular delays
end

--- Zone/login event handler: triggers delayed initialization with context-aware timing.
-- Called on: initial login, /reload, zone changes, instance entry.
--
-- Why delayed start:
-- - Initial login: GetNetStats() returns 0 for ~3-5s while WoW establishes connection
-- - Reload/zone: Minor delay ensures API stability after loading screen
--
-- @param self table LatencyGuard addon object
-- @param isInitialLogin boolean True on first login, false on /reload or zone
-- @param isReloadingUi boolean True on /reload, false on zone/login
-- @return nil No return value
function LatencyGuard:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
	local delay = isInitialLogin and C.INITIAL_LOGIN_DELAY or C.RELOAD_OR_ZONE_DELAY
	H.DebugPrint("PLAYER_ENTERING_WORLD (initial=%s, reload=%s) -> delay=%d", tostring(isInitialLogin), tostring(isReloadingUi), delay)

	if not State.enableGuard then
		return
	end

	C_Timer_After(delay, function()
		-- Double-check enableGuard in case it was toggled during delay
		if not State.enableGuard then
			return
		end

		if InCombatLockdown() then
			State.isUpdateQueued = true
			LatencyGuard:Defer(function()
				Engine.UpdateSpellQueueWindow()
				Engine.StartRegularUpdates()
			end)
		else
			Engine.UpdateSpellQueueWindow()
			Engine.StartRegularUpdates()
		end
	end)
end

--[[-----------------------------------------------------------------------------
Combat Event Handlers
-----------------------------------------------------------------------------]]

--- Post-combat event handler: resumes monitoring and processes queued updates.
-- Called when player exits combat (PLAYER_REGEN_ENABLED fires).
-- Safe to call SetCVar again after this event.
-- @param self table LatencyGuard addon object
-- @return nil No return value
function LatencyGuard:PLAYER_REGEN_ENABLED()
	H.DebugPrint("Player exited combat")
	if not State.enableGuard then
		return
	end

	-- Resume periodic monitoring after combat
	Engine.StartRegularUpdates()

	-- Process any updates that were queued during combat
	if State.isUpdateQueued then
		-- Use Dashi's defer system for post-combat updates
		self:Defer(Engine.UpdateSpellQueueWindow)
	end
end

--- Combat entry event handler: stops timers to prevent tainted CVar writes.
-- Called when player enters combat (PLAYER_REGEN_DISABLED fires).
-- CRITICAL: CVar writes during combat can taint secure execution.
-- @param self table LatencyGuard addon object
-- @return nil No return value
function LatencyGuard:PLAYER_REGEN_DISABLED()
	H.DebugPrint("Player entered combat")
	-- Stop timers to ensure no updates run during combat (taint avoidance)
	Engine.StopAllTimers()
	-- Flag that we owe an update once combat ends
	State.isUpdateQueued = true
end

--[[-----------------------------------------------------------------------------
CVar Monitoring
-----------------------------------------------------------------------------]]

--- CVar change event handler: monitors external SpellQueueWindow modifications.
-- Fires whenever any CVar changes (user, addon, Blizzard UI).
-- Used for diagnostics: alerts user if another addon/macro overwrites SQW.
-- @param self table LatencyGuard addon object
-- @param cvarName string Name of the changed CVar
-- @return nil No return value
function LatencyGuard:CVAR_UPDATE(cvarName)
	-- Monitor SpellQueueWindow changes from other sources
	if cvarName == "SpellQueueWindow" and State.enableGuard then
		local newValue = H.SafeGetCVar("SpellQueueWindow", C.DEFAULT_SPELL_QUEUE_WINDOW)
		H.DebugPrint("SpellQueueWindow externally changed to: %d", newValue)

		if State.userWantsFeedback and math_abs(newValue - State.lastKnownLatency) > State.latencyThreshold then
			self:Printf(L["SpellQueueWindow externally modified to: %d"], newValue)
		end
	end
end

--[[-----------------------------------------------------------------------------
Settings Callbacks
-----------------------------------------------------------------------------]]

-- NOTE: These callbacks are registered in the main LatencyGuard.lua file
-- after all modules are loaded, to ensure proper initialization order.
-- They are defined here for logical organization but exported to main file.

--- Callback for latency threshold setting changes.
-- @param value number New threshold value from settings UI
local function OnLatencyThresholdChanged(value)
	State.latencyThreshold = H.ValidateLatencyThreshold(value)
	H.DebugPrint("Latency threshold updated to: %d", State.latencyThreshold)
	if State.userWantsFeedback and not State.isInitializing then
		LatencyGuard:Printf("Latency threshold updated to: %d", State.latencyThreshold)
	end
end

--- Callback for user feedback setting changes.
-- @param value boolean New feedback enabled state
local function OnUserWantsFeedbackChanged(value)
	State.userWantsFeedback = value or false
	H.DebugPrint("Feedback messages %s", State.userWantsFeedback and "enabled" or "disabled")
	if State.userWantsFeedback and not State.isInitializing then
		LatencyGuard:Print("Feedback messages enabled")
	end
end

--- Callback for debug mode setting changes.
-- @param value boolean New debug mode state
local function OnEnableDebugModeChanged(value)
	State.enableDebugMode = value or false
	if State.userWantsFeedback and not State.isInitializing then
		if State.enableDebugMode then
			LatencyGuard:Print(L["Debug mode enabled - expect verbose output"])
		else
			LatencyGuard:Print(L["Debug mode disabled"])
		end
	end
end

--- Callback for max latency cap setting changes.
-- @param value number New cap value from settings UI
local function OnMaxLatencyCapChanged(value)
	State.maxLatencyCap = H.ValidateMaxLatencyCap(value)
	H.DebugPrint("Maximum latency cap updated to: %d", State.maxLatencyCap)
	if State.userWantsFeedback and not State.isInitializing then
		LatencyGuard:Printf("Maximum latency cap set to: %d ms", State.maxLatencyCap)
	end
end

--- Callback for enable/disable setting changes.
-- Manages timer lifecycle when addon is toggled on/off.
-- @param value boolean New enabled state
local function OnEnableGuardChanged(value)
	local wasEnabled = State.enableGuard
	State.enableGuard = value or false

	H.DebugPrint("LatencyGuard %s", State.enableGuard and "enabled" or "disabled")

	if State.enableGuard and not wasEnabled then
		-- Enabling the addon
		if InCombatLockdown() then
			State.isUpdateQueued = true
			LatencyGuard:Defer(function()
				Engine.StartRegularUpdates()
				Engine.UpdateSpellQueueWindow()
				if State.userWantsFeedback and not State.isInitializing then
					LatencyGuard:Print(L["LatencyGuard enabled"])
				end
			end)
		else
			Engine.StartRegularUpdates()
			Engine.UpdateSpellQueueWindow()
			if State.userWantsFeedback and not State.isInitializing then
				LatencyGuard:Print(L["LatencyGuard enabled"])
			end
		end
	elseif not State.enableGuard and wasEnabled then
		-- Disabling the addon
		Engine.StopAllTimers()
		State.isUpdateQueued = false
		if State.userWantsFeedback and not State.isInitializing then
			LatencyGuard:Print(L["LatencyGuard disabled"])
		end
	end
end

--[[-----------------------------------------------------------------------------
Addon Lifecycle Events
-----------------------------------------------------------------------------]]

--- ADDON_LOADED event: Fires once after TOC files loaded.
-- SavedVariables available at this point (Dashi auto-loads LatencyGuardDB).
-- @param self table LatencyGuard addon object
-- @param addonName string Name of the loaded addon
-- @return boolean True to auto-unregister event
LatencyGuard:RegisterEvent("ADDON_LOADED", function(self, addonName)
	if addonName == "LatencyGuard" then
		H.DebugPrint("LatencyGuard addon loaded")
		-- Mark initialization as complete after a brief delay to allow all settings to load
		C_Timer_After(1, function()
			State.isInitializing = false
		end)
		return true -- Unregister this event
	end
end)

--- PLAYER_LOGOUT event: Cleanup on logout to prevent memory leaks.
-- @param self table LatencyGuard addon object
-- @return boolean True to auto-unregister event
LatencyGuard:RegisterEvent("PLAYER_LOGOUT", function(self)
	H.DebugPrint("Player logout - cleaning up timers")
	Engine.StopAllTimers()
	State.isUpdateQueued = false
	return true -- Unregister this event
end)

--[[-----------------------------------------------------------------------------
Export Callbacks to Namespace
-----------------------------------------------------------------------------]]

-- Export callbacks for registration in main file
LatencyGuard.EventCallbacks = {
	OnLatencyThresholdChanged = OnLatencyThresholdChanged,
	OnUserWantsFeedbackChanged = OnUserWantsFeedbackChanged,
	OnEnableDebugModeChanged = OnEnableDebugModeChanged,
	OnMaxLatencyCapChanged = OnMaxLatencyCapChanged,
	OnEnableGuardChanged = OnEnableGuardChanged,
}
