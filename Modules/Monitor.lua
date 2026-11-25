--[[
	LatencyGuard - Monitor
	Measures the connection. Owns every sample buffer; other modules only read.

	Network:  GetNetStats every few seconds. The client refreshes its latency
	          figure about every 30 seconds, so a reading is stored only when
	          it changed or a full refresh passed. Repeats would fake stability.

	Frame rate: sampled once a second, only while the readout is shown.
--]]

local _, ns = ...
local C, F = ns.C, ns.F

local GetNetStats = GetNetStats
local GetFramerate = GetFramerate
local GetTime = GetTime
local C_Timer = C_Timer
local type = type

local NET = C.NET

local Monitor = {}
ns.Monitor = Monitor

local netRing = ns.NewRing(NET.NET_SAMPLES)
local fpsRing = ns.NewRing(NET.FPS_SAMPLES)

local net = { home = nil, world = nil, bwIn = nil, bwOut = nil }
local lastStored, lastStoredAt
local listeners = {}

-- ---------------------------------------------------------------------------
-- Listeners: modules that react to a fresh network reading
-- ---------------------------------------------------------------------------
function Monitor:AddListener(fn)
	listeners[#listeners + 1] = fn
end

local function Notify()
	for i = 1, #listeners do
		listeners[i]()
	end
end

-- ---------------------------------------------------------------------------
-- Network
-- ---------------------------------------------------------------------------
local function Usable(value)
	if F.IsSecret(value) or type(value) ~= "number" then
		return nil
	end
	return value
end

local function PollNet()
	local bwIn, bwOut, home, world = GetNetStats()
	bwIn, bwOut, home, world = Usable(bwIn), Usable(bwOut), Usable(home), Usable(world)

	-- Zero means "not measured yet", which happens right after login.
	net.home = (home and home > 0) and home or nil
	net.world = (world and world > 0) and world or nil
	net.bwIn, net.bwOut = bwIn, bwOut

	local w = net.world
	if w then
		local now = GetTime()
		if w ~= lastStored or not lastStoredAt or now - lastStoredAt >= NET.REFRESH then
			netRing:Push(w)
			lastStored, lastStoredAt = w, now
		end
	end

	Notify()
end
Monitor.Poll = PollNet

function Monitor:GetNet()
	return net.world, net.home, net.bwIn, net.bwOut
end

--- Mean, spread, min, max and sample count of stored world-latency readings.
function Monitor:GetNetSummary()
	local mean, sd, low, high = netRing:Summary()
	return mean, sd, low, high, netRing:Count()
end

-- ---------------------------------------------------------------------------
-- Frame rate
-- ---------------------------------------------------------------------------
function Monitor:SampleFps()
	local fps = GetFramerate()
	if type(fps) == "number" and fps > 0 then
		fpsRing:Push(fps)
	end
	return fps
end

--- Current, average and 5th-percentile low frame rate.
function Monitor:GetFps()
	local mean = fpsRing:Summary()
	return GetFramerate(), mean, fpsRing:Percentile(0.05)
end

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------
function Monitor:ResetSamples()
	netRing:Clear()
	fpsRing:Clear()
	lastStored, lastStoredAt = nil, nil
end

ns:OnLogin(function()
	PollNet()
	-- The ticker lives for the session; GetNetStats is a cheap read.
	C_Timer.NewTicker(NET.POLL, PollNet)
end)
