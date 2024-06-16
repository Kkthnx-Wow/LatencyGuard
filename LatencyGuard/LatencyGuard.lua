-- Global variables
local _, latencyGuard = ...

-- Cached WoW API and global variables
local InCombatLockdown, GetNetStats, GetCVar, SetCVar, max, tonumber = InCombatLockdown, GetNetStats, GetCVar, SetCVar, math.max, tonumber
local C_Timer = C_Timer

local isUpdateQueued = false
local zeroLatencyTicker = nil
local UPDATE_INTERVAL = 10 -- Regular update interval in seconds
local elapsedTimeSinceLastUpdate = 0

-- Forward declaration of the function
local updateSpellQueueWindow
local latencyThreshold = nil
local userWantsFeedback = nil
local enableGuard = nil

latencyGuard:RegisterOptionCallback("latencyThreshold", function(value)
	latencyThreshold = value
end)

latencyGuard:RegisterOptionCallback("userWantsFeedback", function(value)
	userWantsFeedback = value
end)

latencyGuard:RegisterOptionCallback("enableGuard", function(value)
	enableGuard = value
end)

-- Function to start a ticker that checks for zero latency
local function startZeroLatencyTicker()
	if zeroLatencyTicker then
		zeroLatencyTicker:Cancel()
	else
	end
	zeroLatencyTicker = C_Timer.NewTicker(10, updateSpellQueueWindow) -- Check every 10 seconds
end

-- Function to update the Spell Queue Window based on latency
function updateSpellQueueWindow()
	if InCombatLockdown() then
		isUpdateQueued = true
		return
	end

	local _, _, latencyHome, latencyWorld = GetNetStats()
	local currentLatency = max(latencyHome, latencyWorld)

	if currentLatency == 0 then
		if not zeroLatencyTicker then
			startZeroLatencyTicker()
		end
		return
	elseif zeroLatencyTicker then
		zeroLatencyTicker:Cancel()
		zeroLatencyTicker = nil
	end

	local currentSQW = tonumber(GetCVar("SpellQueueWindow"))
	if math.abs(currentSQW - currentLatency) >= latencyThreshold then
		SetCVar("SpellQueueWindow", currentLatency)
		if userWantsFeedback then
			latencyGuard:Print("SpellQueueWindow updated to:", currentLatency, "from:", currentSQW)
		end
	end

	isUpdateQueued = false
end

-- Event handling for initial setup and post-combat updates
latencyGuard:RegisterEvent("PLAYER_LOGIN", function()
	if enableGuard then
		updateSpellQueueWindow()
	end
end)

latencyGuard:RegisterEvent("PLAYER_REGEN_ENABLED", function()
	if enableGuard and isUpdateQueued then
		updateSpellQueueWindow()
	end
end)

-- Regular update check
local updateCheckFrame = latencyGuard:CreateFrame("Frame")
updateCheckFrame:SetScript("OnUpdate", function(_, elapsed)
	if not enableGuard then
		return
	end

	elapsedTimeSinceLastUpdate = elapsedTimeSinceLastUpdate + elapsed
	if elapsedTimeSinceLastUpdate >= UPDATE_INTERVAL then
		elapsedTimeSinceLastUpdate = 0
		updateSpellQueueWindow()
	end
end)
