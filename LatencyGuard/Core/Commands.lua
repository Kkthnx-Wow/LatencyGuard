--[[
	LatencyGuard - Commands & Options
	-------------------------------------------------------------------------
	`/lg` slash command and the Blizzard Settings panel. Settings write directly
	to the active profile and modules apply changes live via OnSettingChanged.
--]]

local _, ns = ...
local F, C, L = ns.F, ns.C, ns.L

local format = string.format
local type = type
local ipairs = ipairs
local C_AddOns = C_AddOns

local function Brand(text)
	return "|c" .. C.BrandHex .. text .. "|r"
end

-- ---------------------------------------------------------------------------
-- Slash commands
-- ---------------------------------------------------------------------------
local handlers = {}

handlers.help = function()
	F.Print(F.Colorize(L["Usage"] .. ":", "brand"))
	F.Print("  /lg help    -", L["Show this help"])
	F.Print("  /lg config  -", L["Open the options panel"])
end

handlers.config = function()
	if ns.OpenOptions then
		ns:OpenOptions()
	else
		handlers.help()
	end
end

local function HandleSlash(input)
	input = (input or ""):gsub("^%s+", ""):gsub("%s+$", "")
	local command = input:match("^(%S*)") or ""
	command = command:lower()
	local handler = handlers[command] or handlers.help
	handler()
end

_G.SLASH_LATENCYGUARD1 = "/lg"
_G.SLASH_LATENCYGUARD2 = "/latencyguard"
_G["SlashCmdList"]["LATENCYGUARD"] = HandleSlash

-- ---------------------------------------------------------------------------
-- Options panel
-- ---------------------------------------------------------------------------
local function ApplyModuleSetting(module, key, value)
	if module.OnSettingChanged then
		module:OnSettingChanged(key, value)
	end
	if module.dbKey then
		ns:TriggerCallback("SettingChanged." .. module.dbKey .. "." .. key, value, module)
	end
end

local OptionBuilder = {}

local function GetDefault(module, key)
	local defaults = ns.defaults.profile[module.dbKey]
	return defaults and defaults[key]
end

local function RegisterSetting(category, module, key, name)
	local variableTbl = ns.db[module.dbKey]
	local defaultValue = GetDefault(module, key)
	local variable = ns.name .. "_" .. module.dbKey .. "_" .. key
	local setting = Settings.RegisterAddOnSetting(category, variable, key, variableTbl, type(defaultValue), name, defaultValue)
	setting:SetValueChangedCallback(function(_, value)
		ApplyModuleSetting(module, key, value)
	end)
	return setting
end

function OptionBuilder:Checkbox(category, module, key, name, tooltip)
	local setting = RegisterSetting(category, module, key, name)
	Settings.CreateCheckbox(category, setting, tooltip)
	return setting
end

function OptionBuilder:Slider(category, module, key, name, tooltip, minValue, maxValue, step)
	local setting = RegisterSetting(category, module, key, name)

	local options = Settings.CreateSliderOptions(minValue, maxValue, step)
	if MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label then
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
			return format("%dms", value)
		end)
	end
	Settings.CreateSlider(category, setting, options, tooltip)
	return setting
end

local GROUP_ORDER = {
	{ key = "general", title = L["General"], desc = L["DESC_GENERAL"] },
}

local GROUP_INDEX = {}
for i = 1, #GROUP_ORDER do
	GROUP_INDEX[GROUP_ORDER[i].key] = i
end

local function SortModules(a, b)
	local ga = GROUP_INDEX[a.group or "general"] or math.huge
	local gb = GROUP_INDEX[b.group or "general"] or math.huge
	if ga ~= gb then
		return ga < gb
	end
	local oa, ob = a.order or 100, b.order or 100
	if oa ~= ob then
		return oa < ob
	end
	return a.name < b.name
end

local CreateSettingsListSectionHeaderInitializer = _G["CreateSettingsListSectionHeaderInitializer"]

local function AddSectionHeader(layout, text)
	if layout and CreateSettingsListSectionHeaderInitializer then
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
	end
end

local function MakeFontString(parent, template)
	local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
	fs:SetJustifyH("LEFT")
	return fs
end

local function CreateLandingFrame()
	local frame = CreateFrame("Frame", nil)

	local title = MakeFontString(frame, "GameFontNormalHuge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(ns.title)

	local meta = MakeFontString(frame, "GameFontDisable")
	meta:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	local author = C_AddOns.GetAddOnMetadata(ns.name, "Author") or "?"
	meta:SetText(format("%s %s   %s %s", L["Version"], Brand(ns.version), L["Author"], Brand(author)))

	local descTitle = MakeFontString(frame, "GameFontNormalLarge")
	descTitle:SetPoint("TOPLEFT", meta, "BOTTOMLEFT", 0, -24)
	descTitle:SetText(L["Landing Desc Title"])

	local descText = MakeFontString(frame, "GameFontHighlight")
	descText:SetPoint("TOPLEFT", descTitle, "BOTTOMLEFT", 0, -8)
	descText:SetWidth(560)
	descText:SetJustifyH("LEFT")
	descText:SetText(format(L["Landing Desc Text"], Brand("Spell Queue Window"), Brand("LatencyGuard")))

	local heading = MakeFontString(frame, "GameFontNormalLarge")
	heading:SetPoint("TOPLEFT", descText, "BOTTOMLEFT", 0, -24)
	heading:SetText(Brand(L["Getting Started"]))

	local row = MakeFontString(frame, "GameFontHighlight")
	row:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 6, -8)
	row:SetText(format("%s  |cffaaaaaa%s|r", Brand("/lg"), L["Open the options panel"]))

	return frame
end

local function BuildOptions()
	if not (Settings and Settings.RegisterVerticalLayoutCategory) then
		return
	end

	local category
	if Settings.RegisterCanvasLayoutCategory then
		category = Settings.RegisterCanvasLayoutCategory(CreateLandingFrame(), ns.title)
	else
		category = Settings.RegisterVerticalLayoutCategory(ns.title)
	end
	ns.settingsCategory = category

	local groupCategory, groupLayout = {}, {}
	if Settings.RegisterVerticalLayoutSubcategory then
		for i = 1, #GROUP_ORDER do
			local g = GROUP_ORDER[i]
			local sub, layout = Settings.RegisterVerticalLayoutSubcategory(category, g.title)
			groupCategory[g.key] = sub
			groupLayout[g.key] = layout

			if g.desc and F.CreateSettingsDescription then
				local desc = F.CreateSettingsDescription(g.desc)
				if desc then
					layout:AddInitializer(desc)
				end
			end
		end
	end

	local ordered = {}
	for i = 1, #ns.modules do
		ordered[i] = ns.modules[i]
	end
	table.sort(ordered, SortModules)

	for i = 1, #ordered do
		local module = ordered[i]
		if module.RegisterOptions then
			local key = groupCategory[module.group] and module.group or "general"
			local moduleCategory = groupCategory[key] or category
			AddSectionHeader(groupLayout[key], module.title or module.name)
			OptionBuilder.layout = groupLayout[key]
			module:RegisterOptions(moduleCategory, OptionBuilder)
			OptionBuilder.layout = nil
		end
	end

	Settings.RegisterAddOnCategory(category)

	function ns:OpenOptions()
		if Settings.OpenToCategory then
			Settings.OpenToCategory(category.ID)
		end
	end
end

ns:RegisterEvent("PLAYER_LOGIN", BuildOptions)
