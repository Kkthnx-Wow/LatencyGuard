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
local F = ns.F

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

local function MigrateDatabase(root)
	-- v0 -> v1: flat LatencyGuardDB { enabled, verbose, tolerance } -> profile tree
	if root.enabled ~= nil and not root.profiles then
		root.profiles = {
			Default = {
				spellQueue = {
					enable = root.enabled,
					verbose = root.verbose ~= false,
					tolerance = type(root.tolerance) == "number" and root.tolerance or 150,
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
	root.profileKeys[ns.C.Player.key] = profileName
	root.profiles[profileName] = root.profiles[profileName] or {}

	ns.db = F.CopyDefaults(ns.defaults.profile, root.profiles[profileName])
	ns.profileName = profileName

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

	ns.global = root.global
	ns:SetProfile(root.profileKeys[ns.C.Player.key] or "Default")
end
