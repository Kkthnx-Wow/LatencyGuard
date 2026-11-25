--[[
	LatencyGuard - Database
	Account-wide settings, because SpellQueueWindow is an account CVar.

	LatencyGuardDB = {
		schemaVersion = 2,
		settings      = { ... see DEFAULTS },
		readoutPos    = { point, relativePoint, x, y } or nil,
		originalSQW   = the player's own value before LatencyGuard first wrote, or nil,
	}

	Older layouts are migrated once:
	  v0  flat { enabled, verbose, tolerance }
	  v1  profiles.Default.spellQueue { enable, tolerance, pvpTolerance, ... }
--]]

local _, ns = ...
local C, F = ns.C, ns.F

local type, pairs, next, tonumber = type, pairs, next, tonumber
local GetCVarDefault = GetCVarDefault

local SCHEMA = 2

local DEFAULTS = {
	enable = true,
	margin = 100,
	pvpSeparate = true,
	pvpMargin = 60,
	adaptive = true,
	respectManual = true,
	verbose = false,
	readout = false,
	readoutLocked = false,
	readoutScale = 1,
	readoutHome = false,
	readoutFps = true,
	readoutQueue = true,
	spikeAlert = false,
	spikeThreshold = 200,
}
ns.DEFAULTS = DEFAULTS

local function Migrate(root)
	local old

	if root.enabled ~= nil and not root.profiles then
		old = { enable = root.enabled ~= false, verbose = root.verbose == true, tolerance = root.tolerance }
	elseif type(root.profiles) == "table" then
		local profile = root.profiles.Default
		old = type(profile) == "table" and profile.spellQueue or nil
	end

	if type(old) == "table" then
		local s = {}
		s.enable = old.enable
		s.verbose = old.verbose
		s.margin = old.tolerance
		s.pvpSeparate = old.pvpSeparate
		s.pvpMargin = old.pvpTolerance
		s.adaptive = old.adaptiveJitter
		s.respectManual = old.respectManual
		root.settings = s
	end

	root.enabled, root.verbose, root.tolerance = nil, nil, nil
	root.profiles, root.profileKeys, root.global = nil, nil, nil
end

--- Fill missing or mistyped values from defaults and clamp numbers.
local function Sanitize(settings)
	for key, default in pairs(DEFAULTS) do
		if type(settings[key]) ~= type(default) then
			settings[key] = default
		end
	end
	for key in pairs(settings) do
		if DEFAULTS[key] == nil then
			settings[key] = nil
		end
	end

	local SQW = C.SQW
	settings.margin = F.Round(F.Clamp(settings.margin, SQW.MARGIN_MIN, SQW.MARGIN_MAX))
	settings.pvpMargin = F.Round(F.Clamp(settings.pvpMargin, SQW.MARGIN_MIN, SQW.MARGIN_MAX))
	settings.readoutScale = F.Clamp(settings.readoutScale, 0.6, 2)
	local ALERT = C.ALERT
	settings.spikeThreshold = F.Round(F.Clamp(settings.spikeThreshold, ALERT.MIN, ALERT.MAX))
end

function ns:SetupDatabase()
	local root = _G.LatencyGuardDB
	if type(root) ~= "table" then
		root = {}
		_G.LatencyGuardDB = root
	end

	if (root.schemaVersion or 0) < SCHEMA then
		local hadOldData = next(root) ~= nil
		Migrate(root)
		root.schemaVersion = SCHEMA
		-- Older versions already rewrote the CVar, so the live value is ours,
		-- not the player's. Restore falls back to the client default instead.
		if hadOldData and root.originalSQW == nil then
			root.originalSQW = tonumber(GetCVarDefault(C.SQW.CVAR)) or C.SQW.DEFAULT
		end
	end

	if type(root.settings) ~= "table" then
		root.settings = {}
	end
	Sanitize(root.settings)

	if type(root.originalSQW) ~= "number" then
		root.originalSQW = nil
	end
	if type(root.readoutPos) ~= "table" then
		root.readoutPos = nil
	end

	ns.root = root
	ns.db = root.settings
end
