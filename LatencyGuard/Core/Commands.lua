--[[
	LatencyGuard - Commands & Options
	-------------------------------------------------------------------------
	`/latencyguard` slash command and the Blizzard Settings panel. Settings write directly
	to the active profile and modules apply changes live via OnSettingChanged.
--]]

local _, ns = ...
local F, C, L = ns.F, ns.C, ns.L

local format = string.format
local type = type
local C_AddOns = C_AddOns

local LOGO_SIZE = 72
local LANDING_WIDTH = 620
local LANDING_HEIGHT = 500

local function MakeFontString(parent, template)
	local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
	fs:SetJustifyH("LEFT")
	return fs
end

local function AddLandingSection(frame, anchor, titleKey, bodyText, spacing)
	local title = MakeFontString(frame, "GameFontNormal")
	title:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -(spacing or 14))
	title:SetText(F.BrandAccent(L[titleKey]))

	local body = MakeFontString(frame, "GameFontHighlightSmall")
	body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
	body:SetPoint("RIGHT", frame, "RIGHT", -24, 0)
	body:SetJustifyH("LEFT")
	body:SetWordWrap(true)
	body:SetSpacing(2)
	body:SetText(bodyText)

	return body
end

local function FormatLatency(ms)
	if ms == nil then
		return L["Pending"]
	end
	return format("%dms", ms)
end

local function FormatBool(value)
	return value and L["Yes"] or L["No"]
end

-- ---------------------------------------------------------------------------
-- Slash commands
-- ---------------------------------------------------------------------------
local handlers = {}

handlers.help = function()
	local cmd, alias = C.Slash.primary, C.Slash.alias
	F.Print(F.Colorize(L["Usage"] .. ":", "brand"))
	F.Print("  ", cmd, "     -", L["Open the options panel"])
	F.Print("  ", alias, "       -", L["Open the options panel"])
	F.Print("  ", cmd, " status -", L["Show diagnostic status"])
	F.Print("  ", cmd, " help   -", L["Show this help"])
end

handlers.status = function()
	local module = ns:GetModule("SpellQueue")
	if not module or not module.GetStatus then
		F.Print(L["Status Unavailable"])
		return
	end

	local status = module:GetStatus()
	F.Print(F.Colorize(L["Status Header"], "brand"))

	F.Print(format("  %s %s", L["Status Version"], F.Brand(ns.version)))
	F.Print(format("  %s %s", L["Status Automation"], FormatBool(status.enabled)))
	F.Print(format("  %s %s", L["Status Verbose"], FormatBool(status.verbose)))
	F.Print(format("  %s %s", L["Status Tolerance"], F.BrandAccent(format("%dms", status.tolerance))))

	if status.adaptiveJitter then
		F.Print(format("  %s %s", L["Status Adaptive Jitter"], FormatBool(true)))
		if status.jitterSamples and status.jitterSamples > 0 then
			F.Print(format(
				"  %s %s (σ %dms, %d/%d samples)",
				L["Status Jitter Margin"],
				F.BrandAccent(format("%dms", status.jitterMargin or 0)),
				status.jitter or 0,
				status.jitterSamples,
				status.jitterSampleMax or C.SpellQueue.JITTER_SAMPLE_MAX
			))
			if status.jitterSamples < (status.jitterMinSamples or 3) then
				F.Print(format("  %s %s", L["Status Jitter Warming"], format("%d/%d", status.jitterSamples, status.jitterMinSamples or 3)))
			end
		else
			F.Print(format("  %s %s", L["Status Jitter Margin"], L["Pending"]))
		end
		if status.effectiveMargin then
			F.Print(format("  %s %s", L["Status Effective Margin"], F.Brand(format("%dms", status.effectiveMargin))))
		end
	else
		F.Print(format("  %s %s", L["Status Adaptive Jitter"], FormatBool(false)))
	end

	F.Print(format("  %s %s", L["Status World Latency"], F.Brand(FormatLatency(status.latencyWorld))))
	if status.latencyHome then
		F.Print(format("  %s %s", L["Status Home Latency"], FormatLatency(status.latencyHome)))
	end

	if status.currentSQW then
		F.Print(format("  %s %s", L["Status Current SQW"], F.BrandAccent(format("%dms", status.currentSQW))))
	else
		F.Print(format("  %s %s", L["Status Current SQW"], L["Pending"]))
	end

	if status.rawTargetSQW then
		F.Print(format("  %s %s", L["Status Raw Target"], F.Brand(format("%dms", status.rawTargetSQW))))
	end

	if status.targetSQW then
		F.Print(format("  %s %s", L["Status Target SQW"], F.BrandAccent(format("%dms", status.targetSQW))))
		if status.rawTargetSQW and status.rawTargetSQW ~= status.targetSQW then
			F.Print(format("  %s %d–%dms", L["Status Clamp"], status.minSQW, status.maxSQW))
		end
	else
		F.Print(format("  %s %s", L["Status Target SQW"], L["Pending"]))
	end

	if status.delta then
		F.Print(format("  %s %dms", L["Status Delta"], status.delta))
	end

	F.Print(format("  %s %s", L["Status Would Apply"], FormatBool(status.wouldApply)))
	F.Print(format("  %s %s", L["Status Pending"], FormatBool(status.pending)))
	F.Print(format("  %s %s", L["Status In Combat"], FormatBool(status.inCombat)))
	F.Print(format("  %s %s", L["Status Ticker"], FormatBool(status.tickerActive)))

	if status.discoveryActive or status.discoveryAttempts > 0 then
		F.Print(format(
			"  %s %s (%d/%d)",
			L["Status Discovery"],
			FormatBool(status.discoveryActive),
			status.discoveryAttempts,
			C.SpellQueue.DISCOVERY_MAX_ATTEMPTS
		))
	end
end

handlers.config = function()
	if ns.OpenOptions then
		ns:OpenOptions()
	else
		handlers.help()
	end
end

handlers["config"] = handlers.config
handlers["help"] = handlers.help
handlers["status"] = handlers.status

local function HandleSlash(input)
	input = (input or ""):gsub("^%s+", ""):gsub("%s+$", "")
	local command = input:match("^(%S*)") or ""
	command = command:lower()
	local handler = handlers[command]
	if not handler then
		handler = (command == "" and handlers.config) or handlers.help
	end
	handler()
end

_G.SLASH_LATENCYGUARD1 = C.Slash.primary
_G.SLASH_LATENCYGUARD2 = C.Slash.alias
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
	if not ns.db or not module.dbKey or not ns.db[module.dbKey] then
		return
	end

	local variableTbl = ns.db[module.dbKey]
	local defaultValue = GetDefault(module, key)
	if defaultValue == nil then
		return
	end
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

local function RefreshLandingStatus(frame)
	if not frame.status then
		return
	end

	local ping = F.GetWorldLatency()
	local sqw = F.GetSpellQueueWindow()
	local pingText = ping and format("%dms", ping) or L["Pending"]
	frame.status:SetText(format(L["Landing Status"], F.Brand(pingText), F.BrandAccent(format("%dms", sqw))))
end

local function CreateLandingFrame()
	local frame = CreateFrame("Frame", nil)
	frame:SetSize(LANDING_WIDTH, LANDING_HEIGHT)

	local sqwTerm = F.Brand(L["Landing Term SQW"])
	local worldTerm = F.Brand(L["Landing Term World Latency"])
	local jitterTerm = F.BrandAccent(L["Landing Term Jitter"])

	local logo = frame:CreateTexture(nil, "ARTWORK")
	logo:SetSize(LOGO_SIZE, LOGO_SIZE)
	logo:SetPoint("TOPLEFT", 16, -16)
	logo:SetTexture(C.Media.Textures.logo)

	local title = MakeFontString(frame, "GameFontNormalHuge")
	title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 16, -4)
	title:SetText(F.BrandTitle())

	local meta = MakeFontString(frame, "GameFontDisable")
	meta:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	local author = C_AddOns.GetAddOnMetadata(ns.name, "Author") or "?"
	meta:SetText(format("%s %s   %s %s", L["Version"], F.Brand(ns.version), L["Author"], F.BrandAccent(author)))

	local status = MakeFontString(frame, "GameFontHighlight")
	status:SetPoint("TOPLEFT", meta, "BOTTOMLEFT", 0, -4)
	frame.status = status

	local divider = frame:CreateTexture(nil, "ARTWORK")
	divider:SetColorTexture(C.Colors.brand[1], C.Colors.brand[2], C.Colors.brand[3], 0.45)
	divider:SetHeight(2)
	divider:SetPoint("TOPLEFT", logo, "BOTTOMLEFT", 0, -14)
	divider:SetPoint("RIGHT", frame, "RIGHT", -24, 0)

	local sectionHow = AddLandingSection(
		frame,
		divider,
		"Landing Section How",
		format(L["Landing Section How Body"], sqwTerm),
		12
	)

	local sectionTradeoff = AddLandingSection(
		frame,
		sectionHow,
		"Landing Section Tradeoff",
		L["Landing Section Tradeoff Body"]
	)

	local sectionAddon = AddLandingSection(
		frame,
		sectionTradeoff,
		"Landing Section Addon",
		format(L["Landing Section Addon Body"], worldTerm, jitterTerm)
	)

	local footer = MakeFontString(frame, "GameFontDisableSmall")
	footer:SetPoint("TOPLEFT", sectionAddon, "BOTTOMLEFT", 0, -12)
	footer:SetPoint("RIGHT", frame, "RIGHT", -24, 0)
	footer:SetJustifyH("LEFT")
	footer:SetWordWrap(true)
	footer:SetSpacing(2)
	footer:SetText(format(
		L["Landing Footer"],
		F.Brand(C.Slash.primary),
		F.Brand(C.Slash.alias),
		F.Brand(C.Slash.primary .. " status")
	))

	frame:SetScript("OnShow", function(self)
		RefreshLandingStatus(self)
	end)
	RefreshLandingStatus(frame)

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
		if not category then
			return
		end
		if Settings.OpenToCategory then
			local id = category.ID
			if not id and category.GetID then
				id = category:GetID()
			end
			if id then
				Settings.OpenToCategory(id)
			end
		end
	end
end

ns:RegisterEvent("PLAYER_LOGIN", BuildOptions)
