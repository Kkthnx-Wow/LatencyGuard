--[[
	LatencyGuard - Options and slash commands
	A landing page with the live report, a Settings subcategory, and
	/latencyguard (alias /latguard). Every setting writes straight into
	ns.db and applies at once.
--]]

local _, ns = ...
local C, F, L = ns.C, ns.F, ns.L

local CreateFrame = CreateFrame
local C_Texture = C_Texture
local C_Timer = C_Timer
local Settings = Settings
local InCombatLockdown = InCombatLockdown
local format = string.format
local tconcat = table.concat
local type = type

local SQW = C.SQW

local settingByKey = {}

-- ---------------------------------------------------------------------------
-- Applying a change
-- ---------------------------------------------------------------------------
local READOUT_KEYS = {
	readout = true,
	readoutLocked = true,
	readoutScale = true,
	readoutHome = true,
	readoutFps = true,
	readoutQueue = true,
}
local ALERT_KEYS = { spikeAlert = true, spikeThreshold = true }

local function OnSettingChanged(key)
	if READOUT_KEYS[key] then
		ns.Readout:Apply()
	elseif ALERT_KEYS[key] then
		ns.Alerts:Check()
	elseif key ~= "verbose" then
		ns.SpellQueue:OnSettingChanged(key)
	end
end

--- Change a setting from code so the Settings control stays in sync.
local function SetOption(key, value)
	local setting = settingByKey[key]
	if setting then
		setting:SetValue(value)
	else
		ns.db[key] = value
		OnSettingChanged(key)
	end
end

-- ---------------------------------------------------------------------------
-- Landing page
-- ---------------------------------------------------------------------------
local reportLines = {}

local function AddReportLine(label, value)
	if not label then
		reportLines[#reportLines + 1] = " "
	else
		reportLines[#reportLines + 1] = format("|cffffd100%s|r  %s", label, value)
	end
end

local function BuildReportText()
	for i = #reportLines, 1, -1 do
		reportLines[i] = nil
	end
	ns.Report(AddReportLine)
	return tconcat(reportLines, "\n")
end

local function CreateLanding()
	local frame = CreateFrame("Frame")
	frame:SetSize(620, 520)

	local logo = frame:CreateTexture(nil, "ARTWORK")
	logo:SetSize(64, 64)
	logo:SetPoint("TOPLEFT", 16, -16)
	logo:SetTexture(C.Media.logo)

	-- Same pieces and proportions as Blizzard's action button: the frame art
	-- is 46x45 for a 45x45 icon, and the rounded-corner mask is 1.5x the icon
	-- and centered (SmallActionButton uses a 45 mask on a 30 icon). A mask
	-- the same size as the icon clips it inward and leaves a dark gap.
	if C_Texture.GetAtlasInfo("UI-HUD-ActionBar-IconFrame") then
		local mask = frame:CreateMaskTexture()
		mask:SetAtlas("UI-HUD-ActionBar-IconFrame-Mask")
		mask:SetSize(64 * 1.5, 64 * 1.5)
		mask:SetPoint("CENTER", logo)
		logo:AddMaskTexture(mask)

		local border = frame:CreateTexture(nil, "OVERLAY")
		border:SetAtlas("UI-HUD-ActionBar-IconFrame")
		border:SetSize(64 * 46 / 45, 64)
		border:SetPoint("TOPLEFT", logo, "TOPLEFT")
	end

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
	title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 14, -6)
	title:SetText(F.Title())

	local meta = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	meta:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	meta:SetText(format("%s %s   %s %s", L["Version"], F.Color(ns.version, "brand"), L["Author"], F.Color(ns.author, "accent")))

	local divider = frame:CreateTexture(nil, "ARTWORK")
	divider:SetColorTexture(0.176, 0.831, 0.749, 0.45)
	divider:SetHeight(2)
	divider:SetPoint("TOPLEFT", logo, "BOTTOMLEFT", 0, -12)
	divider:SetPoint("RIGHT", frame, "RIGHT", -24, 0)

	local how = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	how:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -12)
	how:SetPoint("RIGHT", frame, "RIGHT", -24, 0)
	how:SetJustifyH("LEFT")
	how:SetSpacing(2)
	how:SetText(L["Landing How"])

	local liveTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	liveTitle:SetPoint("TOPLEFT", how, "BOTTOMLEFT", 0, -16)
	liveTitle:SetText(L["Live Report"])

	local report = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	report:SetPoint("TOPLEFT", liveTitle, "BOTTOMLEFT", 0, -8)
	report:SetPoint("RIGHT", frame, "RIGHT", -24, 0)
	report:SetJustifyH("LEFT")
	report:SetSpacing(3)

	local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	footer:SetPoint("TOPLEFT", report, "BOTTOMLEFT", 0, -16)
	footer:SetPoint("RIGHT", frame, "RIGHT", -24, 0)
	footer:SetJustifyH("LEFT")
	footer:SetText(format(L["Landing Footer"], C.Slash[1], C.Slash[2]))

	local ticker
	local function RefreshReport()
		report:SetText(BuildReportText())
	end
	frame:SetScript("OnShow", function()
		RefreshReport()
		if not ticker then
			ticker = C_Timer.NewTicker(1, RefreshReport)
		end
	end)
	frame:SetScript("OnHide", function()
		if ticker then
			ticker:Cancel()
			ticker = nil
		end
	end)

	return frame
end

-- ---------------------------------------------------------------------------
-- Settings controls
-- ---------------------------------------------------------------------------
local function Register(category, key, name)
	local default = ns.DEFAULTS[key]
	local setting = Settings.RegisterAddOnSetting(category, "LatencyGuard_" .. key, key, ns.db, type(default), name, default)
	setting:SetValueChangedCallback(function(_, value)
		OnSettingChanged(key, value)
	end)
	settingByKey[key] = setting
	return setting
end

local function Checkbox(category, key, name, tooltip)
	Settings.CreateCheckbox(category, Register(category, key, name), tooltip)
end

local function Slider(category, key, name, tooltip, low, high, step, formatter)
	local options = Settings.CreateSliderOptions(low, high, step)
	options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, formatter)
	Settings.CreateSlider(category, Register(category, key, name), options, tooltip)
end

local function Header(layout, text)
	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
end

local function Button(layout, name, buttonText, onClick, tooltip)
	layout:AddInitializer(CreateSettingsButtonInitializer(name, buttonText, onClick, tooltip, true))
end

local function FormatMs(value)
	return format("%dms", value)
end

local function FormatScale(value)
	return format("%.1fx", value)
end

local category

local function BuildSettings()
	category = Settings.RegisterCanvasLayoutCategory(CreateLanding(), F.Title())
	local sub, layout = Settings.RegisterVerticalLayoutSubcategory(category, L["General"])

	Header(layout, L["Spell Queue"])
	Checkbox(sub, "enable", L["Automate Spell Queue Window"], L["Automate Spell Queue Window Tooltip"])
	Slider(sub, "margin", L["Tolerance Buffer"], L["Safety Margin Tooltip"], SQW.MARGIN_MIN, SQW.MARGIN_MAX, 10, FormatMs)
	Checkbox(sub, "adaptive", L["Adaptive Jitter Margin"], L["Adaptive Tooltip"])
	Checkbox(sub, "pvpSeparate", L["Separate PvP Margin"], L["Separate PvP Margin Tooltip"])
	Slider(sub, "pvpMargin", L["PvP Safety Margin"], L["PvP Safety Margin Tooltip"], SQW.MARGIN_MIN, SQW.MARGIN_MAX, 10, FormatMs)
	Checkbox(sub, "respectManual", L["Respect Manual Changes"], L["Respect Manual Changes Tooltip"])
	Checkbox(sub, "verbose", L["Enable Chat Feedback"], L["Enable Chat Feedback Tooltip"])
	Button(layout, L["Restore Spell Queue"], L["Restore"], function()
		ns.RunCommand("restore")
	end, L["Restore Spell Queue Tooltip"])

	Header(layout, L["Readout"])
	Checkbox(sub, "readout", L["Show Readout"], L["Show Readout Tooltip"])
	Checkbox(sub, "readoutLocked", L["Lock Readout"], L["Lock Readout Tooltip"])
	Checkbox(sub, "readoutHome", L["Readout Show Home"], L["Readout Show Home Tooltip"])
	Checkbox(sub, "readoutFps", L["Readout Show Fps"], nil)
	Checkbox(sub, "readoutQueue", L["Readout Show Queue"], nil)
	Slider(sub, "readoutScale", L["Readout Scale"], nil, 0.6, 2, 0.1, FormatScale)
	Button(layout, L["Reset Readout Position"], L["Reset"], function()
		ns.Readout:ResetPosition()
	end, nil)

	Header(layout, L["Alerts"])
	Checkbox(sub, "spikeAlert", L["Spike Alert Option"], L["Spike Alert Option Tooltip"])
	Slider(sub, "spikeThreshold", L["Spike Threshold"], L["Spike Threshold Tooltip"], C.ALERT.MIN, C.ALERT.MAX, C.ALERT.STEP, FormatMs)

	Settings.RegisterAddOnCategory(category)
end

function ns:OpenOptions()
	if category then
		Settings.OpenToCategory(category:GetID())
	end
end

-- ---------------------------------------------------------------------------
-- Slash commands
-- ---------------------------------------------------------------------------
local commands = {}

function commands.status()
	F.Print(L["Status Header"])
	ns.Report(function(label, value)
		if label then
			DEFAULT_CHAT_FRAME:AddMessage(format("  |cffffd100%s|r  %s", label, value))
		end
	end)
end

function commands.resume()
	F.Print(ns.SpellQueue:Resume() and L["Resumed"] or L["Not Paused"])
end

function commands.restore()
	local deferred = InCombatLockdown()
	if ns.db.enable then
		-- Turning automation off is what restores, and keeps it from rewriting.
		SetOption("enable", false)
	else
		ns.SpellQueue:Restore()
	end
	local value = F.Color(F.Ms(ns.root.originalSQW or SQW.DEFAULT), "accent")
	F.Print(format(deferred and L["Restore After Combat"] or L["Restored"], value))
end

function commands.readout()
	SetOption("readout", not ns.db.readout)
end

function commands.reset()
	ns.Monitor:ResetSamples()
	F.Print(L["Samples Reset"])
end

function commands.help()
	local cmd = C.Slash[1]
	F.Print(L["Usage"])
	DEFAULT_CHAT_FRAME:AddMessage(format("  %s  %s", cmd, L["Help Options"]))
	DEFAULT_CHAT_FRAME:AddMessage(format("  %s status  %s", cmd, L["Help Status"]))
	DEFAULT_CHAT_FRAME:AddMessage(format("  %s readout  %s", cmd, L["Help Readout"]))
	DEFAULT_CHAT_FRAME:AddMessage(format("  %s resume  %s", cmd, L["Help Resume"]))
	DEFAULT_CHAT_FRAME:AddMessage(format("  %s restore  %s", cmd, L["Help Restore"]))
	DEFAULT_CHAT_FRAME:AddMessage(format("  %s reset  %s", cmd, L["Help Reset"]))
end

function ns.RunCommand(name)
	local fn = commands[name]
	if fn then
		fn()
	end
end

local function HandleSlash(input)
	local name = (input or ""):match("^%s*(%S*)"):lower()
	if name == "" then
		ns:OpenOptions()
	else
		(commands[name] or commands.help)()
	end
end

SLASH_LATENCYGUARD1 = C.Slash[1]
SLASH_LATENCYGUARD2 = C.Slash[2]
SlashCmdList.LATENCYGUARD = HandleSlash

ns:OnLogin(BuildSettings)
