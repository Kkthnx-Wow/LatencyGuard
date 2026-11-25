--[[
	LatencyGuard - Readout
	A small movable line: world latency, frame rate and the live spell queue.
	Hover for the full report. It runs a one-second ticker only while shown,
	so a hidden readout costs nothing.

	ns.Report(add) also feeds the tooltip, the options page and the status
	command, so all three always agree.
--]]

local _, ns = ...
local C, F, L = ns.C, ns.F, ns.L

local CreateFrame = CreateFrame
local C_Timer = C_Timer
local GameTooltip = GameTooltip
local GetCVar = GetCVar
local UIParent = UIParent
local tonumber, tostring = tonumber, tostring
local format = string.format
local floor, abs = math.floor, math.abs
local tconcat = table.concat

-- ---------------------------------------------------------------------------
-- Shared report
-- ---------------------------------------------------------------------------
local LOW_LATENCY_NAMES = {
	[0] = "GX_ADAPTER_AUTO_DETECT",
	[1] = "VIDEO_OPTIONS_DISABLED",
	[2] = "VIDEO_OPTIONS_BUILTIN",
	[3] = "VIDEO_OPTIONS_NVIDIA_REFLEX",
	[4] = "VIDEO_OPTIONS_NVIDIA_REFLEX_BOOST",
	[5] = "VIDEO_OPTIONS_INTEL_XELL",
}

local function LowLatencyModeText()
	local mode = tonumber(GetCVar("LowLatencyMode") or "")
	if not mode then
		return nil
	end
	local name = LOW_LATENCY_NAMES[mode] and _G[LOW_LATENCY_NAMES[mode]] or tostring(mode)
	return name, mode == 1
end

--- Emits the report through `add(label, value)`. `add()` with no label is a gap.
function ns.Report(add)
	local Monitor, SpellQueue = ns.Monitor, ns.SpellQueue
	local world, home, bwIn, bwOut = Monitor:GetNet()

	add(L["World Latency"], F.LatencyText(world))
	add(L["Home Latency"], F.LatencyText(home))

	local _, spread, low, high, count = Monitor:GetNetSummary()
	if count >= 2 then
		add(L["Latency Range"], format("%s - %s  (%s %s)", F.Ms(low), F.Ms(high), L["spread"], F.Ms(spread)))
	end

	if bwIn and bwOut then
		add(L["Bandwidth"], format("%.1f / %.1f KB/s", bwIn, bwOut))
	end

	local fps, avg, lowFps = Monitor:GetFps()
	if avg then
		add(L["Frame Rate"], format("%s  (%s %d, %s %d)", F.FpsText(fps), L["avg"], floor(avg + 0.5), L["low"], floor(lowFps + 0.5)))
	else
		add(L["Frame Rate"], F.FpsText(fps))
	end

	add()

	local s = SpellQueue:GetStatus()
	add(L["Spell Queue"], F.Color(F.Ms(s.current), "accent"))
	if not s.enabled then
		add(L["Automation"], F.Color(L["Off"], "muted"))
	elseif s.target then
		local line = format("%s = %s + %s + %s", F.Ms(s.target), F.Ms(s.world), F.Ms(s.margin), F.Ms(s.headroom))
		add(L["Target"], line)
		add(" ", F.Color(L["Target Parts"], "muted"))
		if s.raw ~= s.target then
			add(" ", F.Color(format(L["Clamped"], C.SQW.MIN, C.SQW.MAX), "muted"))
		end
		add(L["Content"], s.context == "pvp" and L["Context PvP"] or L["Context PvE"])
	else
		add(L["Target"], F.Color(L["Waiting For Latency"], "muted"))
	end

	if s.enabled then
		local state
		if s.blocked then
			state = F.Color(L["State Blocked"], "bad")
		elseif s.paused and s.paused > 0 then
			state = F.Color(format(L["State Paused"], floor(s.paused / 60 + 0.5)), "warn")
		elseif s.pending then
			state = F.Color(L["State Combat"], "warn")
		elseif s.holding then
			state = L["State Holding"]
		elseif s.target and abs(s.current - s.target) < C.SQW.DEADBAND then
			state = F.Color(format(L["State On Target"], C.SQW.DEADBAND), "good")
		else
			state = F.Color(L["State Updating"], "good")
		end
		add(L["State"], state)
	end

	if ns.db.spikeAlert then
		add(L["Spike Alert Label"], format(L["Spike Alert Value"], F.Ms(ns.db.spikeThreshold)))
	end

	local llm, disabled = LowLatencyModeText()
	if llm then
		add()
		add(L["Low Latency Mode"], disabled and F.Color(llm, "warn") or llm)
		if disabled then
			add(" ", F.Color(L["Low Latency Advice"], "muted"))
		end
	end
end

-- ---------------------------------------------------------------------------
-- Readout frame
-- ---------------------------------------------------------------------------
local Readout = {}
ns.Readout = Readout

local frame, text, ticker

local function AddTooltipLine(label, value)
	if not label then
		GameTooltip:AddLine(" ")
	else
		GameTooltip:AddDoubleLine(label, value, 1, 0.82, 0, 1, 1, 1)
	end
end

local function ShowTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
	GameTooltip:ClearLines()
	GameTooltip:AddLine(F.Title())
	ns.Report(AddTooltipLine)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(ns.db.readoutLocked and L["Readout Hint Locked"] or L["Readout Hint"], 0.6, 0.6, 0.6)
	GameTooltip:Show()
end

local parts = {}

local function Refresh()
	local db = ns.db
	local fps = ns.Monitor:SampleFps()
	local world, home = ns.Monitor:GetNet()

	local n = 1
	parts[1] = F.LatencyText(world)
	if db.readoutHome then
		n = n + 1
		parts[n] = format("%s %s", L["home"], F.LatencyText(home))
	end
	if db.readoutFps then
		n = n + 1
		parts[n] = format("%s %s", F.FpsText(fps), L["fps"])
	end
	if db.readoutQueue then
		n = n + 1
		parts[n] = format("%s %s", L["SQW"], F.Color(F.Ms(ns.SpellQueue:GetCurrent()), "accent"))
	end
	text:SetText(tconcat(parts, "  ", 1, n))
	frame:SetSize(text:GetStringWidth() + 16, text:GetStringHeight() + 10)
	if GameTooltip:IsOwned(frame) then
		ShowTooltip(frame)
	end
end

local function SavePosition()
	local point, _, relativePoint, x, y = frame:GetPoint(1)
	ns.root.readoutPos = { point, relativePoint, floor(x + 0.5), floor(y + 0.5) }
end

local function ApplyPosition()
	frame:ClearAllPoints()
	local pos = ns.root.readoutPos
	if pos and pos[1] then
		frame:SetPoint(pos[1], UIParent, pos[2] or pos[1], pos[3] or 0, pos[4] or 0)
	else
		frame:SetPoint("TOP", UIParent, "TOP", 0, -120)
	end
end

local function Create()
	frame = CreateFrame("Frame", "LatencyGuardReadout", UIParent)
	frame:SetFrameStrata("MEDIUM")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")

	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.06, 0.05, 0.04, 0.75)

	local edge = frame:CreateTexture(nil, "BORDER")
	edge:SetPoint("BOTTOMLEFT")
	edge:SetPoint("BOTTOMRIGHT")
	edge:SetHeight(1)
	edge:SetColorTexture(0.176, 0.831, 0.749, 0.8)

	text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("CENTER", 0, 1)

	frame:SetScript("OnDragStart", function(self)
		if not ns.db.readoutLocked then
			self:StartMoving()
		end
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		SavePosition()
	end)
	frame:SetScript("OnMouseUp", function(_, button)
		if button == "RightButton" and ns.OpenOptions then
			ns:OpenOptions()
		end
	end)
	frame:SetScript("OnEnter", ShowTooltip)
	frame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	frame:SetScript("OnShow", function()
		Refresh()
		if not ticker then
			ticker = C_Timer.NewTicker(1, Refresh)
		end
	end)
	frame:SetScript("OnHide", function()
		if ticker then
			ticker:Cancel()
			ticker = nil
		end
	end)

	frame:Hide()
	ApplyPosition()
end

--- Show, hide, rescale and reposition to match the settings.
function Readout:Apply()
	local db = ns.db
	if not frame then
		if not db.readout then
			return
		end
		Create()
	end
	frame:SetScale(db.readoutScale)
	frame:SetShown(db.readout)
	if frame:IsShown() then
		Refresh()
	end
end

function Readout:ResetPosition()
	ns.root.readoutPos = nil
	if frame then
		ApplyPosition()
	end
end

ns:OnLogin(function()
	Readout:Apply()
end)
