local ADDON_NAME, NS = ...
NS.Modules.Config = {}
local Module = NS.Modules.Config

-- Cache Globals
local _G = _G
local CreateFrame = CreateFrame
local math_floor = math.floor
local string_format = string.format
local GameTooltip = GameTooltip
local C_AddOns_GetAddOnMetadata = C_AddOns.GetAddOnMetadata

-- Default reference for Reset function
local DEFAULTS = {
	enabled = true,
	verbose = true,
	tolerance = 150,
}

-- Branding colors
local COL_GOLD = "|cFFFFD700"
local COL_BLUE = "|cff00ccff"
local COL_RED = "|cFFFF0000"

-- Text Content
local DESC_LONG = "The " .. COL_GOLD .. "Spell Queue Window|r is a hidden game setting that controls the 'buffer time' for your next ability. \n\n" .. COL_BLUE .. "LatencyGuard|r monitors your real-time world ping and adjusts this window so your gameplay feels snappy without losing the ability to queue spells effectively."

-- Helper: Add standardized tooltips
local function AddTooltip(widget, title, text)
	widget:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(title, 1, 1, 1)
		GameTooltip:AddLine(text, 1, 0.82, 0, true)
		GameTooltip:Show()
	end)
	widget:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

function Module:Init()
	local panel = CreateFrame("Frame", nil, UIParent)
	panel.name = ADDON_NAME
	self.panel = panel

	-- Header
	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(ADDON_NAME .. " Configuration")

	-- Description Box
	local subtext = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtext:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
	subtext:SetWidth(400)
	subtext:SetJustifyH("LEFT")
	subtext:SetText(DESC_LONG)

	-- Checkbox: Enable
	local cbEnable = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
	cbEnable:SetPoint("TOPLEFT", subtext, "BOTTOMLEFT", 0, -24)
	cbEnable.Text:SetText("Automate Spell Queue Window")
	cbEnable:SetChecked(LatencyGuardDB.enabled)
	cbEnable:SetScript("OnClick", function(self)
		LatencyGuardDB.enabled = self:GetChecked()
		NS.Modules.Logic:UpdateQueueWindow()
	end)
	AddTooltip(cbEnable, "Automation Status", "If checked, the addon will handle all Spell Queue adjustments.\n\n" .. COL_RED .. "Note:|r Disabling this stops all updates immediately.")
	self.cbEnable = cbEnable

	-- Checkbox: Verbose
	local cbVerbose = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
	cbVerbose:SetPoint("TOPLEFT", cbEnable, "BOTTOMLEFT", 0, -12)
	cbVerbose.Text:SetText("Enable Chat Feedback")
	cbVerbose:SetChecked(LatencyGuardDB.verbose)
	cbVerbose:SetScript("OnClick", function(self)
		LatencyGuardDB.verbose = self:GetChecked()
	end)
	AddTooltip(cbVerbose, "Verbose Mode", "Prints a message in your chat log whenever the Spell Queue Window is updated with a new target value.")
	self.cbVerbose = cbVerbose

	-- Slider: Tolerance
	local slider = CreateFrame("Slider", ADDON_NAME .. "ToleranceSlider", panel, "OptionsSliderTemplate")
	slider:SetPoint("TOPLEFT", cbVerbose, "BOTTOMLEFT", 20, -45)
	slider:SetMinMaxValues(0, 300)
	slider:SetValueStep(10)
	slider:SetObeyStepOnDrag(true)
	slider:SetWidth(250)

	_G[slider:GetName() .. "Low"]:SetText("0ms")
	_G[slider:GetName() .. "High"]:SetText("300ms")
	local sliderText = _G[slider:GetName() .. "Text"]

	slider:SetValue(LatencyGuardDB.tolerance)
	sliderText:SetText(string_format("Tolerance Buffer: %dms", LatencyGuardDB.tolerance))

	slider:SetScript("OnValueChanged", function(self, value)
		value = math_floor(value)
		LatencyGuardDB.tolerance = value
		sliderText:SetText(string_format("Tolerance Buffer: %dms", value))
		NS.Modules.Logic:UpdateQueueWindow()
	end)
	AddTooltip(slider, "Tolerance Buffer", "This value is added to your current world ping.\n\nHigh values (200+) are safer for high-latency connections.\nLow values (50-100) are better for high-end competitive play.")
	self.slider = slider

	-- Button: Reset to Defaults
	local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	resetBtn:SetPoint("BOTTOMLEFT", 16, 16)
	resetBtn:SetSize(140, 26)
	resetBtn:SetText("Reset to Defaults")
	resetBtn:SetScript("OnClick", function()
		LatencyGuardDB.enabled = DEFAULTS.enabled
		LatencyGuardDB.verbose = DEFAULTS.verbose
		LatencyGuardDB.tolerance = DEFAULTS.tolerance

		-- Sync UI elements
		self.cbEnable:SetChecked(DEFAULTS.enabled)
		self.cbVerbose:SetChecked(DEFAULTS.verbose)
		self.slider:SetValue(DEFAULTS.tolerance)

		NS.Utils:Print("Settings have been reset.")
		NS.Modules.Logic:UpdateQueueWindow()
	end)
	AddTooltip(resetBtn, "Factory Reset", "Restore all addon settings to their original values.")

	-- Version String
	local version = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	version:SetPoint("BOTTOMRIGHT", -16, 16)
	version:SetText("v" .. (C_AddOns_GetAddOnMetadata(ADDON_NAME, "Version") or "2.0.2"))

	-- Category Registration
	if Settings and Settings.RegisterCanvasLayoutCategory then
		local category = Settings.RegisterCanvasLayoutCategory(panel, ADDON_NAME)
		Settings.RegisterAddOnCategory(category)
		self.category = category
	else
		InterfaceOptions_AddCategory(panel)
	end
end

function Module:Open()
	if Settings and Settings.OpenToCategory then
		Settings.OpenToCategory(self.category:GetID())
	else
		InterfaceOptionsFrame_OpenToCategory(self.panel)
	end
end
