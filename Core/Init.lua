--[[
	LatencyGuard - Init
	Namespace, constants, small helpers and the load lifecycle.
	Every other file receives the same namespace through `local _, ns = ...`.
--]]

local addonName, ns = ...

local CreateFrame = CreateFrame
local C_AddOns = C_AddOns
local select, tostring = select, tostring
local floor = math.floor
local format = string.format
local tconcat = table.concat
local pcall = pcall
local geterrorhandler = geterrorhandler
local issecretvalue = issecretvalue

_G.LatencyGuard = ns

ns.name = addonName
ns.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"
ns.author = C_AddOns.GetAddOnMetadata(addonName, "Author") or "?"

-- Missing keys fall back to the key itself so a gap never breaks the UI.
ns.L = setmetatable({}, {
	__index = function(_, key)
		return key
	end,
})

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local C = {}
ns.C = C

C.SQW = {
	CVAR = "SpellQueueWindow",
	DEFAULT = 400, -- client default
	MIN = 100, -- below this most connections start dropping queued casts
	MAX = 400, -- client default is also the practical ceiling
	MARGIN_MIN = 0,
	MARGIN_MAX = 300,
	JITTER_CAP = 150, -- adaptive headroom never adds more than this
	DEADBAND = 15, -- ignore target moves smaller than this
	NARROW_HOLD = 45, -- seconds a lower target must hold before we narrow
	YIELD = 600, -- seconds to step aside after an outside change
}

C.NET = {
	POLL = 5, -- seconds between GetNetStats reads
	REFRESH = 30, -- the client refreshes its latency figure about this often
	NET_SAMPLES = 20, -- distinct world-latency readings kept
	NET_MIN_SAMPLES = 3,
	FPS_SAMPLES = 60, -- one per second while the readout is shown
	-- Blizzard micro menu thresholds (MainMenuBarMicroButtons.lua)
	GOOD = 300,
	WARN = 600,
}

C.ALERT = {
	MIN = 100,
	MAX = 1000,
	STEP = 50,
	RECOVER = 0.8, -- a spike ends once latency is back under 80% of the threshold
}

C.Colors = {
	brand = "2dd4bf",
	accent = "c9a227",
	good = "40c057",
	warn = "ffd100",
	bad = "e64d4d",
	muted = "9a9a9a",
	white = "ffffff",
}

C.Media = {
	logo = "Interface\\AddOns\\LatencyGuard\\Media\\Icon256.blp",
}

C.Slash = { "/latencyguard", "/latguard" }

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local F = {}
ns.F = F

function F.Color(text, key)
	return format("|cff%s%s|r", C.Colors[key] or key, tostring(text))
end

function F.Title()
	return format("|cff%sLatency|cff%sGuard|r", C.Colors.brand, C.Colors.accent)
end

function F.Ms(value)
	if value == nil then
		return ns.L["n/a"]
	end
	return format("%dms", floor(value + 0.5))
end

--- Latency colored by Blizzard's own micro menu thresholds.
function F.LatencyText(ms)
	if ms == nil then
		return F.Color(ns.L["n/a"], "muted")
	end
	local key = (ms > C.NET.WARN and "bad") or (ms > C.NET.GOOD and "warn") or "good"
	return F.Color(F.Ms(ms), key)
end

function F.FpsText(fps)
	if fps == nil then
		return F.Color(ns.L["n/a"], "muted")
	end
	local key = (fps < 30 and "bad") or (fps < 60 and "warn") or "good"
	return F.Color(format("%d", floor(fps + 0.5)), key)
end

function F.Clamp(value, low, high)
	if value < low then
		return low
	elseif value > high then
		return high
	end
	return value
end

function F.Round(value)
	return floor(value + 0.5)
end

--- True when `value` is a Secret Value. Always false on clients without them.
function F.IsSecret(value)
	return issecretvalue ~= nil and issecretvalue(value) == true
end

local printBuffer = {}
function F.Print(...)
	local n = select("#", ...)
	printBuffer[1] = F.Title() .. ":"
	for i = 1, n do
		printBuffer[i + 1] = tostring((select(i, ...)))
	end
	DEFAULT_CHAT_FRAME:AddMessage(tconcat(printBuffer, " ", 1, n + 1))
end

-- ---------------------------------------------------------------------------
-- Lifecycle
--   ns:OnLoad(fn)  runs once on ADDON_LOADED, after saved variables exist.
--   ns:OnLogin(fn) runs once on PLAYER_LOGIN.
-- A failing callback reports through the error handler and does not stop
-- the others from running.
-- ---------------------------------------------------------------------------
local loadQueue, loginQueue = {}, {}

function ns:OnLoad(fn)
	loadQueue[#loadQueue + 1] = fn
end

function ns:OnLogin(fn)
	loginQueue[#loginQueue + 1] = fn
end

local function RunQueue(queue)
	for i = 1, #queue do
		local ok, err = pcall(queue[i])
		if not ok then
			geterrorhandler()(err)
		end
	end
end

local lifecycle = CreateFrame("Frame")
lifecycle:RegisterEvent("ADDON_LOADED")
lifecycle:RegisterEvent("PLAYER_LOGIN")
lifecycle:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 ~= addonName then
			return
		end
		self:UnregisterEvent("ADDON_LOADED")
		ns:SetupDatabase()
		RunQueue(loadQueue)
		loadQueue = nil
	elseif event == "PLAYER_LOGIN" then
		self:UnregisterEvent("PLAYER_LOGIN")
		self:SetScript("OnEvent", nil)
		RunQueue(loginQueue)
		loginQueue = nil
	end
end)
