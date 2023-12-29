-- LatencyGuard Configuration Panel

LatencyGuard = LatencyGuard or {}
LatencyGuard.Settings = LatencyGuard.Settings or {
	enabled = true,
	userWantsFeedback = true,
	latencyThreshold = 10,
}

-- Panel Setup
local panel = CreateFrame("Frame", "LatencyGuardConfigPanel", InterfaceOptionsFramePanelContainer)
panel.name = "LatencyGuard"
InterfaceOptions_AddCategory(panel)

-- Icon Setup
local ICON_PATH = "Interface\\AddOns\\LatencyGuard\\LatencyGuardIcon.tga"
local icon = panel:CreateTexture(nil, "ARTWORK")
icon:SetSize(64, 64)
icon:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
icon:SetTexture(ICON_PATH)

-- Title Setup
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -10)
title:SetText("LatencyGuard Configuration")

-- Subtext Setup
local subText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
subText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
subText:SetJustifyH("LEFT")
subText:SetJustifyV("TOP")
subText:SetText("Customize the behavior of LatencyGuard")

-- Declare the controls here to ensure they're defined before SaveSettings
local enableCheckbox, feedbackCheckbox, thresholdSlider

-- Function to save settings
local function SaveSettings()
	if enableCheckbox and feedbackCheckbox and thresholdSlider then
		LatencyGuard.Settings.enabled = enableCheckbox:GetChecked()
		LatencyGuard.Settings.userWantsFeedback = feedbackCheckbox:GetChecked()
		LatencyGuard.Settings.latencyThreshold = thresholdSlider:GetValue()
		print("Settings saved.")
	end
end

-- Function to update addon behavior based on settings
local function UpdateAddonBehavior()
	-- Add code here to update the addon's behavior based on the settings
end

-- Enable/Disable Checkbox
enableCheckbox = CreateFrame("CheckButton", "LatencyGuardEnableCheckbox", panel, "UICheckButtonTemplate")
enableCheckbox:SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -30)
enableCheckbox.text = _G[enableCheckbox:GetName() .. "Text"]
enableCheckbox.text:SetText("Enable LatencyGuard")
enableCheckbox:SetScript("OnClick", function(self)
	UpdateAddonBehavior()
	SaveSettings()
end)

-- Feedback Checkbox
feedbackCheckbox = CreateFrame("CheckButton", "LatencyGuardFeedbackCheckbox", panel, "UICheckButtonTemplate")
feedbackCheckbox:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -10)
feedbackCheckbox.text = _G[feedbackCheckbox:GetName() .. "Text"]
feedbackCheckbox.text:SetText("Enable Feedback Messages")
feedbackCheckbox:SetScript("OnClick", function(self)
	UpdateAddonBehavior()
	SaveSettings()
end)

-- Latency Threshold Slider
thresholdSlider = CreateFrame("Slider", "LatencyGuardThresholdSlider", panel, "OptionsSliderTemplate")
thresholdSlider:SetPoint("TOPLEFT", feedbackCheckbox, "BOTTOMLEFT", -5, -40)
thresholdSlider:SetMinMaxValues(1, 100)
thresholdSlider:SetValueStep(1)
thresholdSlider:SetObeyStepOnDrag(true)
thresholdSlider:SetValue(LatencyGuard.Settings.latencyThreshold)

-- Slider Labels
_G[thresholdSlider:GetName() .. "Low"]:SetText("1")
_G[thresholdSlider:GetName() .. "High"]:SetText("100")
_G[thresholdSlider:GetName() .. "Text"]:SetText("Latency Threshold: " .. LatencyGuard.Settings.latencyThreshold)

thresholdSlider:SetScript("OnValueChanged", function(self, value)
	value = math.floor(value)
	_G[self:GetName() .. "Text"]:SetText("Latency Threshold: " .. value)
	SaveSettings()
end)

-- Tooltip for Slider
thresholdSlider:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText("Latency Threshold", 1, 1, 1)
	GameTooltip:AddLine("Adjust this value to set the latency threshold for your addon.", nil, nil, nil, true)
	GameTooltip:Show()
end)
thresholdSlider:SetScript("OnLeave", GameTooltip_Hide)

-- Function to load settings
local function LoadSettings()
	thresholdSlider:SetValue(LatencyGuard.Settings.latencyThreshold)
	enableCheckbox:SetChecked(LatencyGuard.Settings.enabled)
	feedbackCheckbox:SetChecked(LatencyGuard.Settings.userWantsFeedback)
	UpdateAddonBehavior()
end

-- Function to restore default settings
local function RestoreDefaults()
	LatencyGuard.Settings = {
		enabled = true,
		userWantsFeedback = true,
		latencyThreshold = 1,
	}
	LoadSettings()
	SaveSettings()
	print("Default settings restored.")
end

-- Restore Defaults Button
local restoreDefaultsButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
restoreDefaultsButton:SetSize(120, 22)
restoreDefaultsButton:SetText("Restore Defaults")
restoreDefaultsButton:SetPoint("TOPLEFT", thresholdSlider, "BOTTOMLEFT", 0, -30)
restoreDefaultsButton:SetScript("OnClick", RestoreDefaults)

-- Event Handling
panel:SetScript("OnEvent", function(self, event, addonName)
	if event == "ADDON_LOADED" and addonName == "LatencyGuard" then
		LoadSettings()
		self:UnregisterEvent("ADDON_LOADED")
		print("LatencyGuard settings loaded.")
	end
end)
panel:RegisterEvent("ADDON_LOADED")
