--[[
	LatencyGuard - Network API
	-------------------------------------------------------------------------
	Thin adapters over Blizzard's connection and spell-queue APIs (12.0.7).
	Centralises version drift so modules never scatter GetCVar fallbacks.

	Blizzard reference:
	  GetNetStats()        -> home + world latency (use world for spell queue)
	  C_Spell.GetSpellQueueWindow() -> current queue window in ms
	  SetCVar("SpellQueueWindow", n) -> write (blocked in combat lockdown)

	Adaptive margin (when enabled):
	  SQW = WorldLatency + HumanMargin + (JITTER_MULTIPLIER × σ)
	  σ = population stddev of recent world-latency samples (ring buffer).
--]]

local _, ns = ...
local C, F = ns.C, ns.F

local GetNetStats = GetNetStats
local GetCVar = GetCVar
local SetCVar = SetCVar
local InCombatLockdown = InCombatLockdown
local C_Spell = C_Spell
local tonumber = tonumber
local floor = math.floor
local sqrt = math.sqrt
local wipe = wipe

local SQ = C.SpellQueue

-- ---------------------------------------------------------------------------
-- Latency
-- ---------------------------------------------------------------------------

--- World-server round-trip latency in ms, or nil when unavailable/secret.
--- Combat and ability input travel on the world connection (not home/realm).
function F.GetWorldLatency()
	local _, _, _, world = GetNetStats()
	if F.IsSecret(world) or not world or world <= 0 then
		return nil
	end
	return world
end

--- Home + world latency when both are readable; nil if either is blocked.
function F.GetLatencyPair()
	local _, _, home, world = GetNetStats()
	if F.IsSecret(home) or F.IsSecret(world) then
		return nil, nil
	end
	return home, world
end

-- ---------------------------------------------------------------------------
-- Jitter sampling (session ring buffer; one sample per GetNetStats change)
-- ---------------------------------------------------------------------------

local jitterBuf = {}
local jitterCount = 0
local jitterNext = 1
local jitterLastRecorded

function F.ResetLatencySamples()
	wipe(jitterBuf)
	jitterCount = 0
	jitterNext = 1
	jitterLastRecorded = nil
end

--- Record a world-latency reading when Blizzard's cached value changes (~30s).
function F.RecordLatencySample(latencyWorld)
	if not latencyWorld or latencyWorld <= 0 then
		return
	end
	if jitterLastRecorded == latencyWorld then
		return
	end
	jitterLastRecorded = latencyWorld

	jitterBuf[jitterNext] = latencyWorld
	jitterNext = jitterNext + 1
	if jitterNext > SQ.JITTER_SAMPLE_MAX then
		jitterNext = 1
	end
	if jitterCount < SQ.JITTER_SAMPLE_MAX then
		jitterCount = jitterCount + 1
	end
end

local function GetJitterSample(index)
	if jitterCount < SQ.JITTER_SAMPLE_MAX then
		return jitterBuf[index]
	end
	local idx = jitterNext + index - 1
	if idx > SQ.JITTER_SAMPLE_MAX then
		idx = idx - SQ.JITTER_SAMPLE_MAX
	end
	return jitterBuf[idx]
end

--- Stddev, min, max, mean of recent world-latency samples (integer ms).
function F.GetJitterStats()
	if jitterCount == 0 then
		return { samples = 0, jitter = 0, min = nil, max = nil, mean = nil }
	end

	local sum = 0
	local minV, maxV = jitterBuf[1], jitterBuf[1]
	for i = 1, jitterCount do
		local v = GetJitterSample(i)
		sum = sum + v
		if v < minV then
			minV = v
		end
		if v > maxV then
			maxV = v
		end
	end

	local mean = sum / jitterCount
	local jitter = 0
	if jitterCount >= 2 then
		local variance = 0
		for i = 1, jitterCount do
			local d = GetJitterSample(i) - mean
			variance = variance + d * d
		end
		jitter = sqrt(variance / jitterCount)
	end

	return {
		samples = jitterCount,
		jitter = floor(jitter + 0.5),
		min = minV,
		max = maxV,
		mean = floor(mean + 0.5),
	}
end

--- Extra margin from jitter: 0 until JITTER_MIN_SAMPLES, then MULTIPLIER × σ.
function F.ComputeJitterMargin(stats, adaptiveEnabled)
	if not adaptiveEnabled or not stats or stats.samples < SQ.JITTER_MIN_SAMPLES then
		return 0
	end
	local jitter = stats.jitter or 0
	if jitter <= 0 then
		return 0
	end
	return floor(SQ.JITTER_MULTIPLIER * jitter + 0.5)
end

--- Clamp user safety margin to slider bounds.
function F.ClampHumanMargin(humanMargin)
	local buffer = humanMargin or 0
	if buffer < SQ.TOLERANCE_MIN then
		return SQ.TOLERANCE_MIN
	end
	if buffer > SQ.TOLERANCE_MAX then
		return SQ.TOLERANCE_MAX
	end
	return buffer
end

--- Human margin + optional jitter term (integer ms).
function F.ComputeEffectiveMargin(humanMargin, stats, adaptiveEnabled)
	return F.ClampHumanMargin(humanMargin) + F.ComputeJitterMargin(stats, adaptiveEnabled)
end

-- ---------------------------------------------------------------------------
-- Spell Queue Window
-- ---------------------------------------------------------------------------

function F.GetSpellQueueWindow()
	if C_Spell and C_Spell.GetSpellQueueWindow then
		local value = C_Spell.GetSpellQueueWindow()
		if F.NotSecret(value) and type(value) == "number" and value > 0 then
			return value
		end
	end

	local cvar = GetCVar(C.SpellQueue.CVAR)
	if F.IsSecret(cvar) then
		return C.SpellQueue.DEFAULT
	end

	return tonumber(cvar) or C.SpellQueue.DEFAULT
end

--- Writes the CVar out of combat. Returns false when deferred or blocked.
function F.SetSpellQueueWindow(ms)
	if InCombatLockdown() then
		return false
	end
	SetCVar(C.SpellQueue.CVAR, floor(ms + 0.5))
	return true
end

--- Ping + effective margin before addon clamping (integer ms).
function F.ComputeSpellQueueRaw(latencyWorld, effectiveMargin)
	return floor(latencyWorld + (effectiveMargin or 0) + 0.5)
end

--- World latency + effective margin, clamped to addon bounds (integer ms).
function F.ComputeSpellQueueTarget(latencyWorld, effectiveMargin)
	local target = F.ComputeSpellQueueRaw(latencyWorld, effectiveMargin)
	if target < SQ.MIN then
		return SQ.MIN
	end
	if target > SQ.MAX then
		return SQ.MAX
	end
	return target
end
