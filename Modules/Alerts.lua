--[[
	LatencyGuard - Alerts
	One chat line when world latency rises past the player's threshold, and
	one when it settles again. The end of a spike needs latency back under
	RECOVER x threshold, so a value hovering at the line cannot spam chat.
	The client refreshes latency about every 30 seconds, so an alert can
	trail the real spike by up to that long.
--]]

local _, ns = ...
local C, F, L = ns.C, ns.F, ns.L

local format = string.format

local ALERT = C.ALERT

local Alerts = {}
ns.Alerts = Alerts

local inSpike = false
local peak = 0

function Alerts:Check()
	local db = ns.db
	if not db.spikeAlert then
		inSpike = false
		return
	end

	local world = ns.Monitor:GetNet()
	if not world then
		return
	end

	local threshold = db.spikeThreshold
	if not inSpike then
		if world > threshold then
			inSpike = true
			peak = world
			F.Print(format(L["Spike Alert"], F.LatencyText(world), F.Ms(threshold)))
		end
	elseif world > peak then
		peak = world
	elseif world <= threshold * ALERT.RECOVER then
		inSpike = false
		F.Print(format(L["Spike Recovered"], F.LatencyText(world), F.Ms(peak)))
	end
end

function Alerts:InSpike()
	return inSpike
end

ns:OnLogin(function()
	ns.Monitor:AddListener(function()
		Alerts:Check()
	end)
end)
