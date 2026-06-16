--[[
	LatencyGuard - Constants
	-------------------------------------------------------------------------
	Static client/player info and the brand palette. Looked up once at login
	and reused everywhere so modules never re-query for session-constant data.
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
-- Player information
-- ---------------------------------------------------------------------------
do
	C.Player = {
		name = UnitName("player"),
		realm = GetRealmName(),
	}
	C.Player.key = C.Player.name .. " - " .. C.Player.realm
end

-- ---------------------------------------------------------------------------
-- Colours
-- ---------------------------------------------------------------------------
C.Colors = {
	red = { 0.90, 0.30, 0.30 },
	green = { 0.40, 0.78, 0.40 },
	yellow = { 1.00, 0.82, 0.00 },
	white = { 1.00, 1.00, 1.00 },
	brand = { 0.00, 0.80, 1.00 }, -- #00CCFF
}

C.BrandHex = "ff00ccff"
