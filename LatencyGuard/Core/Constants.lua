--[[
	LatencyGuard - Constants
	-------------------------------------------------------------------------
	Static client/player info, Blizzard-aligned network thresholds, and the
	brand palette. Session-constant values live here so hot paths never
	re-query the API for data that cannot change mid-login.
--]]

local _, ns = ...
local C = ns.C

local UnitName = UnitName
local GetRealmName = GetRealmName
local GetLocale = GetLocale
local GetBuildInfo = GetBuildInfo

-- ---------------------------------------------------------------------------
-- Client information
-- ---------------------------------------------------------------------------
do
	local version, build, _, interface = GetBuildInfo()
	C.Client = {
		version = version,
		build = build,
		interface = interface,
		locale = GetLocale(),
		isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE,
	}
end

-- ---------------------------------------------------------------------------
-- Player information (key is finalized in Database:SetupDatabase at login)
-- ---------------------------------------------------------------------------
do
	C.Player = {
		name = UnitName("player"),
		realm = GetRealmName(),
		key = nil,
	}
end

-- ---------------------------------------------------------------------------
-- Network (Blizzard PerformanceBar / MicroMenu thresholds, 12.0.7)
--   MainMenuBarMicroButtons.lua: green <= 300ms, yellow <= 600ms, red above.
-- ---------------------------------------------------------------------------
C.Network = {
	LOW_LATENCY_MS = 300,
	MEDIUM_LATENCY_MS = 600,
	-- GetNetStats() only refreshes about every 30 seconds (Connection API).
	STATS_REFRESH_SEC = 30,
}

-- ---------------------------------------------------------------------------
-- Spell Queue Window (CVars.lua: default 400, account CVar, combat-locked)
--   Read via C_Spell.GetSpellQueueWindow(); write via SetCVar (no setter API).
--   Tune from world latency — combat traffic uses the world connection, not home.
-- ---------------------------------------------------------------------------
C.SpellQueue = {
	CVAR = "SpellQueueWindow",
	DEFAULT = 400,
	-- Practical floor per community tuning (queue < ~100ms often gaps on typical connections)
	MIN = 100,
	MAX = 400,
	HYSTERESIS = 40, -- target-movement + drift; see wow-spell-queue-research.mdc
	TICK_STEADY = 30, -- matched to C.Network.STATS_REFRESH_SEC below
	TICK_DISCOVERY = 2,
	TOLERANCE_MIN = 0,
	TOLERANCE_MAX = 300,
	DISCOVERY_MAX_ATTEMPTS = 15,
	-- Jitter-aware margin: SQW = RTT + humanMargin + (JITTER_MULTIPLIER × σ)
	JITTER_SAMPLE_MAX = 25,
	JITTER_MIN_SAMPLES = 3,
	JITTER_MULTIPLIER = 2,
}

C.SpellQueue.TICK_STEADY = C.Network.STATS_REFRESH_SEC

-- ---------------------------------------------------------------------------
-- Brand palette — Warcraft UI inspired (matches icon art)
--   Primary:  #2DD4BF  arcane teal (signal / latency)
--   Accent:   #C9A227  aged gold (guard / trim)
--   Surface:  #1A1410  weathered stone (icon background)
-- ---------------------------------------------------------------------------
C.Colors = {
	red = { 0.90, 0.30, 0.30 },
	green = { 0.40, 0.78, 0.40 },
	yellow = { 1.00, 0.82, 0.00 },
	white = { 1.00, 1.00, 1.00 },
	brand = { 0.176, 0.831, 0.749 },
	brandAccent = { 0.788, 0.635, 0.153 },
	surface = { 0.102, 0.078, 0.063 },
	latencyGood = { 0.176, 0.831, 0.749 },
	latencyWarn = { 0.788, 0.635, 0.153 },
	latencyBad = { 0.90, 0.30, 0.30 },
}

C.BrandHex = "ff2dd4bf"
C.BrandAccentHex = "ffc9a227"

-- ---------------------------------------------------------------------------
-- Slash commands — avoid /lg (conflicts with LedgerGoblin)
-- ---------------------------------------------------------------------------
C.Slash = {
	primary = "/latencyguard",
	alias = "/latguard",
}

-- ---------------------------------------------------------------------------
-- Media — addon art paths (square 256 source, scaled in UI)
-- ---------------------------------------------------------------------------
C.Media = {
	Textures = {
		logo = "Interface\\AddOns\\LatencyGuard\\Media\\Icon256.blp",
		logo64 = "Interface\\AddOns\\LatencyGuard\\Media\\Icon64.blp",
	},
}
