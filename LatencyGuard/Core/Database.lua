--[[
	LatencyGuard - Database
	-------------------------------------------------------------------------
	Lightweight saved-variable manager with a single default profile. Modules
	register defaults at load time via `ns:RegisterDefaults`, then read/write
	through `ns.db` once it is built on ADDON_LOADED.

	Legacy v1 installs stored settings flat on the root table (`enabled`,
	`verbose`, `tolerance`). Setup migrates those into `profiles.Default`.
--]]

local _, ns = ...
local F, C = ns.F, ns.C

local UnitName = UnitName
local GetRealmName = GetRealmName
local floor = math.floor
local max = math.max
local min = math.min

ns.defaults = {
	profile = {},
	global = {},
}

function ns:RegisterDefaults(defaults, scope)
	scope = scope or "profile"
	F.CopyDefaults(defaults, ns.defaults[scope])
end

local DB_SCHEMA_VERSION = 1

local migrations = {}

local SQ = C.SpellQueue

local function GetPlayerKey()
	local name = UnitName("player") or "Unknown"
	local realm = GetRealmName() or "Unknown"
	return name .. " - " .. realm
end

local function SanitizeSpellQueue(settings)
	if type(settings) ~= "table" then
		return
	end

	if type(settings.tolerance) ~= "number" then
		settings.tolerance = 100
	else
		settings.tolerance = floor(max(SQ.TOLERANCE_MIN, min(SQ.TOLERANCE_MAX, settings.tolerance)) + 0.5)
	end

	if type(settings.enable) ~= "boolean" then
		settings.enable = true
	end

	if type(settings.verbose) ~= "boolean" then
		settings.verbose = false
	end

	if type(settings.adaptiveJitter) ~= "boolean" then
		settings.adaptiveJitter = true
	end
end

local function MigrateDatabase(root)
	-- v0 -> v1: flat LatencyGuardDB { enabled, verbose, tolerance } -> profile tree
	if root.enabled ~= nil and not root.profiles then
		local tolerance = type(root.tolerance) == "number" and root.tolerance or 100
		root.profiles = {
			Default = {
				spellQueue = {
					enable = root.enabled,
					verbose = root.verbose ~= false,
					tolerance = tolerance,
				},
			},
		}
		root.profileKeys = root.profileKeys or {}
		root.global = root.global or {}
		root.enabled = nil
		root.verbose = nil
		root.tolerance = nil
	end

	local version = root.schemaVersion or 0
	for v = version + 1, DB_SCHEMA_VERSION do
		local step = migrations[v]
		if step then
			step(root)
		end
	end
	root.schemaVersion = DB_SCHEMA_VERSION
end

function ns:SetProfile(profileName)
	local root = _G.LatencyGuardDB
	root.profileKeys[C.Player.key] = profileName
	root.profiles[profileName] = root.profiles[profileName] or {}

	ns.db = F.CopyDefaults(ns.defaults.profile, root.profiles[profileName])
	ns.profileName = profileName

	SanitizeSpellQueue(ns.db.spellQueue)

	if ns.OnProfileChanged then
		ns:OnProfileChanged(profileName)
	end
end

function ns:SetupDatabase()
	local root = _G.LatencyGuardDB or {}
	_G.LatencyGuardDB = root
	root.profiles = root.profiles or {}
	root.profileKeys = root.profileKeys or {}
	root.global = F.CopyDefaults(ns.defaults.global, root.global)

	MigrateDatabase(root)

	C.Player.name = UnitName("player") or C.Player.name
	C.Player.realm = GetRealmName() or C.Player.realm
	C.Player.key = GetPlayerKey()

	ns.global = root.global
	ns:SetProfile(root.profileKeys[C.Player.key] or "Default")
end
