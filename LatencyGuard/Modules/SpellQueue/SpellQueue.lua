--[[
	LatencyGuard - Spell Queue
	-------------------------------------------------------------------------
	Keeps SpellQueueWindow matched to world latency + safety margin.

	Formula:
	  margin = humanMargin + (2 × jitterσ)   [when adaptive jitter enabled]
	  target = clamp(worldPing + margin, 100..400)

	See .cursor/rules/wow-spell-queue-research.mdc for theory and tuning.
--]]

local _, ns = ...
local F, L, C = ns.F, ns.L, ns.C

local C_Timer = C_Timer
local InCombatLockdown = InCombatLockdown
local format = string.format
local math_abs = math.abs

local SQ = C.SpellQueue

ns:RegisterDefaults({
	spellQueue = {
		enable = true,
		verbose = false,
		tolerance = 100,
		adaptiveJitter = true,
	},
})

local SpellQueue = ns:NewModule("SpellQueue", "spellQueue", {
	group = "general",
	title = L["Spell Queue"],
	order = 10,
})

local pendingUpdate = false
local discoveryActive = false
local discoveryAttempts = 0
local lastAppliedTarget
local ticker

-- ---------------------------------------------------------------------------
-- Margin resolution
-- ---------------------------------------------------------------------------
local function ResolveMargin(settings)
	local stats = F.GetJitterStats()
	local human = F.ClampHumanMargin(settings and settings.tolerance)
	local adaptive = settings and settings.adaptiveJitter
	local jitterMargin = F.ComputeJitterMargin(stats, adaptive)
	return human + jitterMargin, stats, human, jitterMargin
end

-- ---------------------------------------------------------------------------
-- Ticker lifecycle
-- ---------------------------------------------------------------------------
local function SteadyTick()
	SpellQueue:UpdateQueueWindow()
end

local function StopTicker()
	pendingUpdate = false
	discoveryActive = false
	discoveryAttempts = 0
	lastAppliedTarget = nil
	F.ResetLatencySamples()
	if ticker then
		ticker:Cancel()
		ticker = nil
	end
end

local function StartTicker()
	if not ticker then
		ticker = C_Timer.NewTicker(SQ.TICK_STEADY, SteadyTick)
	end
end

local function ScheduleDiscovery()
	if discoveryActive or discoveryAttempts >= SQ.DISCOVERY_MAX_ATTEMPTS then
		return
	end

	discoveryActive = true
	discoveryAttempts = discoveryAttempts + 1
	C_Timer.After(SQ.TICK_DISCOVERY, function()
		discoveryActive = false
		SpellQueue:UpdateQueueWindow()
	end)
end

local function NeedsSpellQueueUpdate(current, target)
	if F.IsSecret(current) or not target then
		return false
	end

	local delta = math_abs(current - target)
	if delta < 1 then
		return false
	end

	local targetMoved = not lastAppliedTarget or math_abs(target - lastAppliedTarget) >= SQ.HYSTERESIS
	return targetMoved or delta >= SQ.HYSTERESIS
end

-- ---------------------------------------------------------------------------
-- Core update
-- ---------------------------------------------------------------------------
function SpellQueue:UpdateQueueWindow()
	if not ns.db or not ns.db.spellQueue.enable then
		return
	end

	local latencyWorld = F.GetWorldLatency()
	if not latencyWorld then
		ScheduleDiscovery()
		return
	end

	F.RecordLatencySample(latencyWorld)
	discoveryAttempts = 0

	if InCombatLockdown() then
		pendingUpdate = true
		return
	end

	local settings = ns.db.spellQueue
	local effectiveMargin, _, humanMargin, jitterMargin = ResolveMargin(settings)
	local target = F.ComputeSpellQueueTarget(latencyWorld, effectiveMargin)
	local current = F.GetSpellQueueWindow()

	if F.IsSecret(current) then
		pendingUpdate = false
		return
	end

	if math_abs(current - target) < 1 then
		lastAppliedTarget = target
		pendingUpdate = false
		return
	end

	if not NeedsSpellQueueUpdate(current, target) then
		pendingUpdate = false
		return
	end

	if not F.SetSpellQueueWindow(target) then
		pendingUpdate = true
		return
	end

	lastAppliedTarget = target
	pendingUpdate = false

	if settings.verbose then
		F.Print(format(
			L["Update Message"],
			F.BrandAccent(format("%dms", target)),
			latencyWorld,
			effectiveMargin,
			humanMargin,
			jitterMargin
		))
	end
end

function SpellQueue:PLAYER_REGEN_ENABLED()
	if pendingUpdate then
		self:UpdateQueueWindow()
	end
end

-- ---------------------------------------------------------------------------
-- Module lifecycle
-- ---------------------------------------------------------------------------
function SpellQueue:OnInitialize()
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function SpellQueue:OnEnable()
	StartTicker()
	self:UpdateQueueWindow()
end

function SpellQueue:OnDisable()
	StopTicker()
end

function SpellQueue:OnSettingChanged(key)
	if key == "enable" then
		if ns.db.spellQueue.enable then
			self:OnEnable()
		else
			self:OnDisable()
		end
		return
	end

	if key == "tolerance" and ns.db.spellQueue.tolerance then
		lastAppliedTarget = nil
		local tolerance = ns.db.spellQueue.tolerance
		if tolerance < SQ.TOLERANCE_MIN then
			ns.db.spellQueue.tolerance = SQ.TOLERANCE_MIN
		elseif tolerance > SQ.TOLERANCE_MAX then
			ns.db.spellQueue.tolerance = SQ.TOLERANCE_MAX
		end
	end

	if key == "adaptiveJitter" or key == "tolerance" then
		lastAppliedTarget = nil
	end

	if ns.db.spellQueue.enable then
		self:UpdateQueueWindow()
	end
end

function SpellQueue:GetStatus()
	local settings = ns.db and ns.db.spellQueue
	local latencyHome, latencyWorldPair = F.GetLatencyPair()
	local latencyWorld = F.GetWorldLatency() or latencyWorldPair
	local current = F.GetSpellQueueWindow()
	local rawTarget
	local target
	local effectiveMargin
	local humanMargin
	local jitterMargin
	local jitterStats

	if latencyWorld and settings then
		effectiveMargin, jitterStats, humanMargin, jitterMargin = ResolveMargin(settings)
		rawTarget = F.ComputeSpellQueueRaw(latencyWorld, effectiveMargin)
		target = F.ComputeSpellQueueTarget(latencyWorld, effectiveMargin)
	end

	local currentReadable = not F.IsSecret(current) and current or nil
	local delta = (target and currentReadable) and math_abs(currentReadable - target) or nil

	return {
		enabled = settings and settings.enable or false,
		verbose = settings and settings.verbose or false,
		adaptiveJitter = settings and settings.adaptiveJitter or false,
		tolerance = settings and settings.tolerance or 0,
		humanMargin = humanMargin,
		jitterMargin = jitterMargin,
		effectiveMargin = effectiveMargin,
		jitter = jitterStats and jitterStats.jitter or 0,
		jitterSamples = jitterStats and jitterStats.samples or 0,
		jitterMin = jitterStats and jitterStats.min or nil,
		jitterMax = jitterStats and jitterStats.max or nil,
		jitterMean = jitterStats and jitterStats.mean or nil,
		latencyWorld = latencyWorld,
		latencyHome = latencyHome,
		rawTargetSQW = rawTarget,
		currentSQW = currentReadable,
		targetSQW = target,
		lastAppliedSQW = lastAppliedTarget,
		delta = delta,
		wouldApply = target and currentReadable and NeedsSpellQueueUpdate(currentReadable, target) or false,
		pending = pendingUpdate,
		inCombat = InCombatLockdown(),
		tickerActive = ticker ~= nil,
		discoveryActive = discoveryActive,
		discoveryAttempts = discoveryAttempts,
		hysteresis = SQ.HYSTERESIS,
		minSQW = SQ.MIN,
		maxSQW = SQ.MAX,
		jitterMinSamples = SQ.JITTER_MIN_SAMPLES,
		jitterSampleMax = SQ.JITTER_SAMPLE_MAX,
	}
end

function SpellQueue:RegisterOptions(category, builder)
	builder:Checkbox(category, self, "enable", L["Automate Spell Queue Window"], L["Automate Spell Queue Window Tooltip"])
	builder:Checkbox(category, self, "adaptiveJitter", L["Adaptive Jitter Margin"], L["Adaptive Jitter Margin Tooltip"])
	builder:Checkbox(category, self, "verbose", L["Enable Chat Feedback"], L["Enable Chat Feedback Tooltip"])
	builder:Slider(category, self, "tolerance", L["Tolerance Buffer"], L["Tolerance Buffer Tooltip"], SQ.TOLERANCE_MIN, SQ.TOLERANCE_MAX, 10)
end
