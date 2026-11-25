--[[
	LatencyGuard - Broker feed
	Publishes a LibDataBroker-1.1 data source that broker displays (data
	texts, broker bars) can show. The library ships in Libs and LibStub
	keeps only the newest copy when several addons embed it. A display addon
	is still needed to see the feed.

	The text follows the network poll (every few seconds). LibDataBroker
	skips its callbacks when the text is unchanged, so steady values cost
	almost nothing.
--]]

local _, ns = ...
local F, L = ns.F, ns.L

local format = string.format
local type = type

local function GetLDB()
	local stub = _G.LibStub
	if type(stub) ~= "table" then
		return nil
	end
	return stub:GetLibrary("LibDataBroker-1.1", true)
end

local dataObject

local function UpdateText()
	local world = ns.Monitor:GetNet()
	dataObject.text = format("%s  %s %s", F.LatencyText(world), L["SQW"], F.Color(F.Ms(ns.SpellQueue:GetCurrent()), "accent"))
end

local function AddTooltipLine(tooltip, label, value)
	if not label then
		tooltip:AddLine(" ")
	else
		tooltip:AddDoubleLine(label, value, 1, 0.82, 0, 1, 1, 1)
	end
end

ns:OnLogin(function()
	local ldb = GetLDB()
	if not ldb then
		return
	end

	dataObject = ldb:NewDataObject(ns.name, {
		type = "data source",
		label = "LatencyGuard",
		icon = "Interface\\AddOns\\LatencyGuard\\Media\\Icon64.blp",
		text = "LatencyGuard",
		OnTooltipShow = function(tooltip)
			tooltip:AddLine(F.Title())
			ns.Report(function(label, value)
				AddTooltipLine(tooltip, label, value)
			end)
			tooltip:AddLine(" ")
			tooltip:AddLine(L["Broker Hint"], 0.6, 0.6, 0.6)
		end,
		OnClick = function(_, button)
			if button == "RightButton" then
				ns.RunCommand("readout")
			else
				ns:OpenOptions()
			end
		end,
	})

	-- NewDataObject returns nil if the name is already taken.
	if not dataObject then
		return
	end
	UpdateText()
	ns.Monitor:AddListener(UpdateText)
end)
