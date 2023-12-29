--[[
    LatencyGuard - World of Warcraft Addon
    Author: Joshua Russell (Kkthnx)
    Copyright (c) 2023 Joshua Russell

    This addon, "LatencyGuard," is developed and maintained by Joshua Russell, also known as Kkthnx.
    It optimizes your gameplay experience by dynamically adjusting the Spell Queue Window based on your current network latency.

    All rights reserved. Redistribution and use in source and binary forms, with or without modification,
    are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice,
       this list of conditions, and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice,
       this list of conditions, and the following disclaimer in the documentation
       and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
    IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
    OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
    OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
    EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

local L = LatencyGuardLocalization

-- Cached WoW API and global variables
local InCombatLockdown, GetNetStats, GetCVar, SetCVar, max, tonumber, print = InCombatLockdown, GetNetStats, GetCVar, SetCVar, math.max, tonumber, print
local C_Timer = C_Timer

local isUpdateQueued = false
local zeroLatencyTicker = nil
local UPDATE_INTERVAL = 10 -- Regular update interval in seconds (10 minutes = 600)
local elapsedTimeSinceLastUpdate = 0

-- Function to start a ticker that checks for zero latency
local function StartZeroLatencyTicker()
	if zeroLatencyTicker then
		-- print("Zero-latency ticker already running, resetting it.")
		zeroLatencyTicker:Cancel()
	else
		-- print("Starting zero-latency ticker.")
	end
	zeroLatencyTicker = C_Timer.NewTicker(10, UpdateSpellQueueWindow) -- Check every 10 seconds
end

-- Function to update the Spell Queue Window based on latency
local function UpdateSpellQueueWindow()
	if InCombatLockdown() then
		isUpdateQueued = true
		-- print("Update queued due to combat lockdown.")
		return
	end

	local _, _, latencyHome, latencyWorld = GetNetStats()
	local currentLatency = max(latencyHome, latencyWorld)
	-- print("Current latency: " .. currentLatency)

	if currentLatency == 0 then
		if not zeroLatencyTicker then
			-- print("Latency is 0, starting zero-latency ticker.")
			StartZeroLatencyTicker()
		end
		return
	elseif zeroLatencyTicker then
		-- print("Non-zero latency found, stopping zero-latency ticker.")
		zeroLatencyTicker:Cancel()
		zeroLatencyTicker = nil
	end

	local currentSQW = tonumber(GetCVar("SpellQueueWindow"))
	if math.abs(currentSQW - currentLatency) >= LatencyGuard.Settings.latencyThreshold then
		SetCVar("SpellQueueWindow", currentLatency)
		if LatencyGuard.Settings.userWantsFeedback then
			print("SpellQueueWindow updated to:", currentLatency, "from:", currentSQW)
		end
	else
		-- print("No significant change in latency, no update needed.")
	end

	isUpdateQueued = false
end

-- Event handling for initial setup and post-combat updates
local eventHandlerFrame = CreateFrame("Frame")
eventHandlerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventHandlerFrame:RegisterEvent("PLAYER_LOGIN")
eventHandlerFrame:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" and LatencyGuard.Settings.enabled then
		UpdateSpellQueueWindow()
	elseif event == "PLAYER_REGEN_ENABLED" and LatencyGuard.Settings.enabled and isUpdateQueued then
		-- print("Combat ended, processing queued update.")
		UpdateSpellQueueWindow()
	end
end)

-- Regular update check
local updateCheckFrame = CreateFrame("Frame")
updateCheckFrame:SetScript("OnUpdate", function(_, elapsed)
	if not LatencyGuard.Settings.enabled then
		return
	end

	elapsedTimeSinceLastUpdate = elapsedTimeSinceLastUpdate + elapsed
	if elapsedTimeSinceLastUpdate >= UPDATE_INTERVAL then
		-- print("Regular update interval reached, updating SpellQueueWindow.")
		elapsedTimeSinceLastUpdate = 0
		UpdateSpellQueueWindow()
	end
end)
