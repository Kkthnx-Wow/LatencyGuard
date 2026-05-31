local ADDON_NAME, NS = ...
NS.Modules.Config = {}
local Module = NS.Modules.Config

-- Cache Globals
local type = type
local string_format = string.format
local C_AddOns_GetAddOnMetadata = C_AddOns.GetAddOnMetadata
local L = NS.L

-- Default reference for Reset function
local DEFAULTS = {
	enabled = true,
	verbose = true,
	tolerance = 150,
}

-- Branding colors
local COL_RED = "|cFFFF0000"
local COL_GOLD = "|cFFFFD700"
local COL_BLUE = "|cff00ccff"

function Module:Init()
	-- Create Canvas Layout for Main Info Page
	local version = C_AddOns_GetAddOnMetadata(ADDON_NAME, "Version") or "Unknown"
	local author = C_AddOns_GetAddOnMetadata(ADDON_NAME, "Author") or "Kkthnx"

	local canvasFrame = CreateFrame("Frame", nil, UIParent)
	local category = Settings.RegisterCanvasLayoutCategory(canvasFrame, ADDON_NAME)
	self.category = category

	local title = canvasFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(string_format(L["Config_Title"], version))

	local authorText = canvasFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	authorText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	authorText:SetText(string_format(L["Config_Author"], COL_GOLD, author))

	local descTitle = canvasFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	descTitle:SetPoint("TOPLEFT", authorText, "BOTTOMLEFT", 0, -24)
	descTitle:SetText(L["Config_DescTitle"])

	local descText = canvasFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	descText:SetPoint("TOPLEFT", descTitle, "BOTTOMLEFT", 0, -8)
	descText:SetWidth(560)
	descText:SetJustifyH("LEFT")
	descText:SetText(string_format(L["Config_DescText"], COL_GOLD, COL_BLUE))

	-- Register Main Category
	Settings.RegisterAddOnCategory(category)

	-- Create Subcategory for Settings
	local subcategory = Settings.RegisterVerticalLayoutSubcategory(category, L["Config_OptionsCategory"])

	-- Enable CheckBox
	local function GetEnable() return LatencyGuardDB.enabled end
	local function SetEnable(value)
		LatencyGuardDB.enabled = value
		NS.Modules.Logic:UpdateQueueWindow()
	end
	local settingEnable = Settings.RegisterProxySetting(subcategory, "LatencyGuard_Enabled", type(DEFAULTS.enabled), L["Config_Enable"], DEFAULTS.enabled, GetEnable, SetEnable)
	Settings.CreateCheckbox(subcategory, settingEnable, string_format(L["Config_EnableTooltip"], COL_RED))

	-- Verbose CheckBox
	local function GetVerbose() return LatencyGuardDB.verbose end
	local function SetVerbose(value) LatencyGuardDB.verbose = value end
	local settingVerbose = Settings.RegisterProxySetting(subcategory, "LatencyGuard_Verbose", type(DEFAULTS.verbose), L["Config_Verbose"], DEFAULTS.verbose, GetVerbose, SetVerbose)
	Settings.CreateCheckbox(subcategory, settingVerbose, L["Config_VerboseTooltip"])

	-- Tolerance Slider
	local function GetTolerance() return LatencyGuardDB.tolerance end
	local function SetTolerance(value)
		LatencyGuardDB.tolerance = value
		NS.Modules.Logic:UpdateQueueWindow()
	end
	local settingTolerance = Settings.RegisterProxySetting(subcategory, "LatencyGuard_Tolerance", type(DEFAULTS.tolerance), L["Config_Tolerance"], DEFAULTS.tolerance, GetTolerance, SetTolerance)
	
	local sliderOptions = Settings.CreateSliderOptions(0, 300, 10)
	sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
		return string_format("%dms", value)
	end)
	
	Settings.CreateSlider(subcategory, settingTolerance, sliderOptions, L["Config_ToleranceTooltip"])
end

function Module:Open()
	if Settings and Settings.OpenToCategory then
		Settings.OpenToCategory(self.category:GetID())
	end
end

