-- Lint config for LatencyGuard. Lua 5.1 plus exactly the WoW globals the
-- addon reads, so a typo or an accidental global shows up as a warning.

std = "lua51"
codes = true
-- Module tables use method syntax even where a method does not read self.
self = false
max_line_length = false

-- Bundled third-party libraries are linted upstream, not here.
exclude_files = { "Libs/", ".luarocks/", ".install/" }

globals = {
	"LatencyGuardDB",
	"LatencyGuard",
	"SlashCmdList",
	"SLASH_LATENCYGUARD1",
	"SLASH_LATENCYGUARD2",
}

read_globals = {
	"C_AddOns",
	"C_Spell",
	"C_Texture",
	"C_Timer",
	"CreateFrame",
	"CreateSettingsButtonInitializer",
	"CreateSettingsListSectionHeaderInitializer",
	"DEFAULT_CHAT_FRAME",
	"GameTooltip",
	"GetCVar",
	"GetCVarDefault",
	"GetFramerate",
	"GetLocale",
	"GetNetStats",
	"GetTime",
	"InCombatLockdown",
	"IsInInstance",
	"LibStub",
	"MinimalSliderWithSteppersMixin",
	"SetCVar",
	"Settings",
	"UIParent",
	"geterrorhandler",
	"issecretvalue",
}

-- The tests build a fake WoW environment, so they define the globals above.
files["tests/"] = {
	std = "+lua51",
	allow_defined_top = true,
	globals = { "FAILED" },
	ignore = { "131", "111", "112", "113", "121", "122", "211", "212", "213", "311", "542" },
}
