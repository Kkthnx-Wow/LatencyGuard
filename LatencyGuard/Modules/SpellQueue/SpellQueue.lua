--[[
	LatencyGuard - Spell Queue
	-------------------------------------------------------------------------
	Monitors world latency and keeps the SpellQueueWindow CVar matched to your
	connection. High ping gets a wider queue window; low ping gets a tighter one.

	SpellQueueWindow is protected in combat, so writes defer until regen clears.
	GetNetStats only refreshes ~every 30s — we poll gently until a reading lands.
--]]

local _, ns = ...
local F, L = ns.F, ns.L

local GetNetStats = GetNetStats
local GetCVar = GetCVar
local SetCVar = SetCVar
local InCombatLockdown = InCombatLockdown
local C_Timer = C_Timer
local format = string.format
local math_max = math.max
local math_abs = math.abs
local tonumber = tonumber

ns:RegisterDefaults({
	spellQueue = {
		enable = true,
		verbose = true,
		tolerance = 150,
	},
})

local SpellQueue = ns:NewModule("SpellQueue", "spellQueue", {
	group = "general",
	title = L["Spell Queue"],
	order = 10,
})

-- Tunables
local TICK_RATE_STEADY = 30
local TICK_RATE_DISCOVERY = 2
local MIN_QUEUE_WINDOW = 100
local MAX_QUEUE_WINDOW = 400
local HYSTERESIS = 40

local pendingUpdate = false
local discoveryActive = false
local ticker

local function SteadyTickerCallback()
	SpellQueue:UpdateQueueWindow()
end

local function StopTicker()
	pendingUpdate = false
	discoveryActive = false
	if ticker then
		ticker:Cancel()
		ticker = nil
	end
end

local function StartTicker()
	if not ticker then
		ticker = C_Timer.NewTicker(TICK_RATE_STEADY, SteadyTickerCallback)
	end
end

local function DiscoveryTimerCallback()
	discoveryActive = false
	SpellQueue:UpdateQueueWindow()
end

function SpellQueue:UpdateQueueWindow()
	if not ns.db.spellQueue.enable then
		return
	end

	local _, _, _, latencyWorld = GetNetStats()

	-- Network telemetry, not combat data — but Midnight taught us not to assume
	-- anything stays readable forever. Skip a cycle rather than error.
	if F.IsSecret(latencyWorld) then
		return
	end

	if not latencyWorld or latencyWorld <= 0 then
		if not discoveryActive then
			discoveryActive = true
			C_Timer.After(TICK_RATE_DISCOVERY, DiscoveryTimerCallback)
		end
		return
	end

	if InCombatLockdown() then
		pendingUpdate = true
		return
	end

	local tolerance = ns.db.spellQueue.tolerance
	local target = latencyWorld + tolerance
	target = math_max(MIN_QUEUE_WINDOW, target)
	if target > MAX_QUEUE_WINDOW then
		target = MAX_QUEUE_WINDOW
	end

	local current = tonumber(GetCVar("SpellQueueWindow")) or MAX_QUEUE_WINDOW

	if math_abs(current - target) >= HYSTERESIS then
		SetCVar("SpellQueueWindow", target)
		pendingUpdate = false

		if ns.db.spellQueue.verbose then
			F.Print(format(L["Update Message"], target, latencyWorld, tolerance))
		end
	end
end

function SpellQueue:PLAYER_REGEN_ENABLED()
	if pendingUpdate then
		self:UpdateQueueWindow()
	end
end

function SpellQueue:OnInitialize()
	if ns.db.spellQueue.verbose then
		F.Print(format(L["Init Message"], ns.version))
	end
	-- Always hooked so a mid-session re-enable can flush a deferred combat write.
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function SpellQueue:OnEnable()
	StartTicker()
	self:UpdateQueueWindow()
end

function SpellQueue:OnSettingChanged(key)
	if key == "enable" then
		if ns.db.spellQueue.enable then
			StartTicker()
			self:UpdateQueueWindow()
		else
			StopTicker()
		end
		return
	end
	if ns.db.spellQueue.enable then
		self:UpdateQueueWindow()
	end
end

function SpellQueue:RegisterOptions(category, builder)
	builder:Checkbox(category, self, "enable", L["Automate Spell Queue Window"], L["Automate Spell Queue Window Tooltip"])
	builder:Checkbox(category, self, "verbose", L["Enable Chat Feedback"], L["Enable Chat Feedback Tooltip"])
	builder:Slider(category, self, "tolerance", L["Tolerance Buffer"], L["Tolerance Buffer Tooltip"], 0, 300, 10)
end
