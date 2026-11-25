--[[
	LatencyGuard - Spell Queue
	Keeps SpellQueueWindow matched to the measured connection.

	  target = clamp(world latency + margin + headroom, 100..400)

	margin    the player's safety margin, or the PvP margin in arenas and
	          battlegrounds when that option is on.
	headroom  (adaptive only) 2 x the spread of recent world-latency
	          readings, capped at JITTER_CAP. Zero until enough samples exist.

	Widening applies at once. Narrowing waits NARROW_HOLD seconds so a short
	calm cannot remove protection right before the next spike. Writes happen
	only out of combat. When something else changes the CVar, the guard
	tells the player once and, by default, steps aside for YIELD seconds.
	Turning automation off restores the player's own value.
--]]

local _, ns = ...
local C, F, L = ns.C, ns.F, ns.L

local CreateFrame = CreateFrame
local C_Spell = C_Spell
local C_Timer = C_Timer
local GetCVar = GetCVar
local GetCVarDefault = GetCVarDefault
local SetCVar = SetCVar
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local IsInInstance = IsInInstance
local tonumber, type = tonumber, type
local abs = math.abs
local min = math.min
local format = string.format

local SQW, NET = C.SQW, C.NET
local CVAR_LOWER = SQW.CVAR:lower()

local SpellQueue = {}
ns.SpellQueue = SpellQueue

local lastWritten -- value we last set and still believe is live
local writing = false
local pendingWrite = false
local pendingRestore = false
local narrowSince
local yieldUntil
local lastContext
local writeBlocked = false
local externalCount, lastExternal = 0, nil
local announcedExternal = false
local synced = false -- set after the first write of the session

-- ---------------------------------------------------------------------------
-- Reading and computing
-- ---------------------------------------------------------------------------
function SpellQueue:GetCurrent()
	local value = C_Spell.GetSpellQueueWindow()
	if not F.IsSecret(value) and type(value) == "number" then
		return value
	end
	return tonumber(GetCVar(SQW.CVAR)) or SQW.DEFAULT
end

local function GetContext()
	local _, instanceType = IsInInstance()
	if instanceType == "arena" or instanceType == "pvp" then
		return "pvp"
	end
	return "pve"
end

--- Headroom for an unstable connection, or 0 when adaptive is off or warming up.
local function GetHeadroom()
	if not ns.db.adaptive then
		return 0
	end
	local _, spread, _, _, count = ns.Monitor:GetNetSummary()
	if count < NET.NET_MIN_SAMPLES or not spread then
		return 0
	end
	return min(SQW.JITTER_CAP, F.Round(2 * spread))
end

--- Target and its parts, or nil while world latency is unknown.
function SpellQueue:ComputeTarget()
	local world = ns.Monitor:GetNet()
	if not world then
		return nil
	end
	local context = GetContext()
	local db = ns.db
	local margin = (context == "pvp" and db.pvpSeparate) and db.pvpMargin or db.margin
	local headroom = GetHeadroom()
	local raw = F.Round(world + margin + headroom)
	return F.Clamp(raw, SQW.MIN, SQW.MAX), world, margin, headroom, context, raw
end

-- ---------------------------------------------------------------------------
-- Writing
-- ---------------------------------------------------------------------------
local function WriteCVar(value)
	writing = true
	local ok = SetCVar(SQW.CVAR, value)
	writing = false
	-- The wrapper returns nil on some builds; only an explicit false is a refusal.
	return ok ~= false
end

local function ApplyTarget(target, current, world, margin, headroom)
	local root = ns.root
	if root.originalSQW == nil then
		root.originalSQW = current
	end

	if not WriteCVar(target) then
		if not writeBlocked then
			writeBlocked = true
			F.Print(L["Write Blocked"])
		end
		return
	end

	writeBlocked = false
	lastWritten = target
	narrowSince = nil
	pendingWrite = false

	-- The first write of a session is a login sync and stays silent.
	if ns.db.verbose and synced then
		F.Print(format(L["Update Message"], F.Color(F.Ms(target), "accent"), world, margin, headroom))
	end
	synced = true
end

--- Something other than LatencyGuard changed the value.
local function OnExternalChange(current)
	lastWritten = nil
	narrowSince = nil
	externalCount = externalCount + 1
	lastExternal = current
	-- The player's latest manual choice is what "restore" should return to.
	ns.root.originalSQW = current

	if ns.db.respectManual then
		yieldUntil = GetTime() + SQW.YIELD
	end
	if not announcedExternal then
		announcedExternal = true
		local key = ns.db.respectManual and "External Change Yield" or "External Change Restore"
		F.Print(format(L[key], F.Color(F.Ms(current), "accent"), SQW.YIELD / 60))
	end
end

local function CheckExternal(current)
	if lastWritten and abs(current - lastWritten) >= 1 then
		OnExternalChange(current)
		return true
	end
	return false
end

function SpellQueue:Update()
	local db = ns.db
	if not db or not db.enable then
		return
	end

	if InCombatLockdown() then
		pendingWrite = true
		return
	end

	local current = self:GetCurrent()
	CheckExternal(current)

	if yieldUntil then
		if GetTime() < yieldUntil then
			return
		end
		yieldUntil = nil
	end

	local target, world, margin, headroom, context = self:ComputeTarget()
	if not target then
		return
	end

	local contextChanged = context ~= lastContext
	lastContext = context

	local diff = target - current
	if abs(diff) < SQW.DEADBAND then
		narrowSince = nil
		pendingWrite = false
		return
	end

	-- Hold back a narrowing of our own value, unless the content type changed.
	if diff < 0 and lastWritten == current and not contextChanged then
		local now = GetTime()
		narrowSince = narrowSince or now
		if now - narrowSince < SQW.NARROW_HOLD then
			return
		end
	else
		narrowSince = nil
	end

	ApplyTarget(target, current, world, margin, headroom)
end

--- Put back the player's own value. Deferred until combat ends.
function SpellQueue:Restore()
	if InCombatLockdown() then
		pendingRestore = true
		return false
	end
	pendingRestore = false
	pendingWrite = false
	local value = ns.root.originalSQW or tonumber(GetCVarDefault(SQW.CVAR)) or SQW.DEFAULT
	lastWritten = nil
	narrowSince = nil
	WriteCVar(value)
	return true, value
end

--- End a pause caused by an outside change.
function SpellQueue:Resume()
	local wasPaused = yieldUntil ~= nil
	yieldUntil = nil
	self:Update()
	return wasPaused
end

--- Called by options when a setting changes.
function SpellQueue:OnSettingChanged(key)
	if key == "enable" then
		if ns.db.enable then
			yieldUntil = nil
			pendingRestore = false
			self:Update()
		else
			self:Restore()
		end
		return
	end
	if key == "respectManual" and not ns.db.respectManual then
		yieldUntil = nil
	end
	-- A new margin should apply now, not after a narrowing hold.
	narrowSince = nil
	lastContext = nil
	self:Update()
end

-- ---------------------------------------------------------------------------
-- Status snapshot for the readout, options page and /latencyguard status.
-- One table is reused; callers must not keep it.
-- ---------------------------------------------------------------------------
local status = {}

function SpellQueue:GetStatus()
	local target, world, margin, headroom, context, raw = self:ComputeTarget()
	status.enabled = ns.db.enable
	status.current = self:GetCurrent()
	status.target = target
	status.raw = raw
	status.world = world
	status.margin = margin
	status.headroom = headroom
	status.context = context or GetContext()
	status.paused = yieldUntil and (yieldUntil - GetTime()) or nil
	status.pending = pendingWrite or pendingRestore
	status.holding = narrowSince ~= nil
	status.blocked = writeBlocked
	status.externalCount = externalCount
	status.lastExternal = lastExternal
	status.original = ns.root.originalSQW
	return status
end

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------
local frame = CreateFrame("Frame")

frame:SetScript("OnEvent", function(_, event, name)
	if event == "PLAYER_REGEN_ENABLED" then
		if pendingRestore then
			SpellQueue:Restore()
		elseif pendingWrite then
			SpellQueue:Update()
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		-- Latency and content type both change across loading screens.
		lastContext = nil
		C_Timer.After(2, ns.Monitor.Poll)
	elseif event == "CVAR_UPDATE" then
		if writing or type(name) ~= "string" or F.IsSecret(name) or name:lower() ~= CVAR_LOWER then
			return
		end
		if ns.db.enable then
			CheckExternal(SpellQueue:GetCurrent())
		end
	end
end)

ns:OnLogin(function()
	frame:RegisterEvent("PLAYER_REGEN_ENABLED")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("CVAR_UPDATE")
	ns.Monitor:AddListener(function()
		SpellQueue:Update()
	end)
	SpellQueue:Update()
end)
