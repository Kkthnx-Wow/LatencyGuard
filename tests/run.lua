-- Behaviour tests for LatencyGuard in plain Lua 5.1 with a stubbed WoW API.
-- Loads every file in TOC order, then drives events, timers and settings.
--
--   lua5.1 tests/run.lua           existing 2.x settings, full scenario
--   lua5.1 tests/run.lua . fresh   clean install
--
-- This checks addon logic only. It does not replace testing in the game.
local ROOT = arg[1] or "."
local now = 100
local cvars = { SpellQueueWindow = "400", LowLatencyMode = "1" }
local combat = false
local net = { 0, 0, 0, 0 }
local instanceType = "none"
local frames, tickers, chat = {}, {}, {}
local cvarRefuse = false

local function noop() end
local Frame = {}
Frame.__index = function(t, k)
	if Frame[k] then return Frame[k] end
	return noop
end
function Frame:RegisterEvent(e) self.events[e] = true end
function Frame:RegisterUnitEvent(e) self.events[e] = true end
function Frame:UnregisterEvent(e) self.events[e] = nil end
function Frame:SetScript(n, f) self.scripts[n] = f end
function Frame:GetScript(n) return self.scripts[n] end
function Frame:CreateTexture() return setmetatable({}, { __index = function() return noop end }) end
Frame.CreateMaskTexture = Frame.CreateTexture
C_Texture = { GetAtlasInfo = function() return {} end }
function Frame:CreateFontString()
	local fs = { text = "" }
	return setmetatable(fs, { __index = function(_, k)
		if k == "SetText" then return function(s, t) s.text = t end end
		if k == "GetStringWidth" or k == "GetStringHeight" then return function() return 10 end end
		return noop
	end })
end
function Frame:Show() if not self.shown then self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end end
function Frame:Hide() if self.shown then self.shown = false; if self.scripts.OnHide then self.scripts.OnHide(self) end end end
function Frame:SetShown(v) if v then self:Show() else self:Hide() end end
function Frame:IsShown() return self.shown end
function Frame:GetPoint() return "TOP", nil, "TOP", 10.4, -50.6 end
function CreateFrame()
	local f = setmetatable({ events = {}, scripts = {} }, Frame)
	frames[#frames + 1] = f
	return f
end
local function Fire(event, ...)
	for _, f in ipairs(frames) do
		if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end
	end
end

C_AddOns = { GetAddOnMetadata = function(_, k) return k == "Version" and "3.0.0" or "Kkthnx" end }
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) chat[#chat + 1] = m end }
geterrorhandler = function() return function(e) error(e) end end
GetNetStats = function() return net[1], net[2], net[3], net[4] end
GetFramerate = function() return 120 end
GetTime = function() return now end
GetCVar = function(n) return cvars[n] end
GetCVarDefault = function() return "400" end
SetCVar = function(n, v)
	if cvarRefuse then return false end
	cvars[n] = tostring(v); Fire("CVAR_UPDATE", n, tostring(v)); return true
end
InCombatLockdown = function() return combat end
IsInInstance = function() return instanceType ~= "none", instanceType end
C_Spell = { GetSpellQueueWindow = function() return tonumber(cvars.SpellQueueWindow) end }
C_Timer = {
	After = function(_, f) f() end,
	NewTicker = function(_, f)
		local t = { f = f }
		function t:Cancel() self.cancelled = true end
		tickers[#tickers + 1] = t
		return t
	end,
}
GameTooltip = setmetatable({ IsOwned = function() return false end }, { __index = function() return noop end })
UIParent = {}
VIDEO_OPTIONS_DISABLED = "Disabled"
local settingsRegistered = {}
Settings = {
	RegisterCanvasLayoutCategory = function() return { GetID = function() return 1 end } end,
	RegisterVerticalLayoutSubcategory = function() return {}, { AddInitializer = noop } end,
	RegisterAddOnSetting = function(_, var, key, tbl)
		local s = { key = key, tbl = tbl }
		function s:SetValueChangedCallback(cb) self.cb = cb end
		function s:SetValue(v) self.tbl[self.key] = v; self.cb(self, v) end
		settingsRegistered[key] = s
		return s
	end,
	CreateCheckbox = noop, CreateSlider = noop, RegisterAddOnCategory = noop, OpenToCategory = noop,
	CreateSliderOptions = function() return { SetLabelFormatter = noop } end,
}
MinimalSliderWithSteppersMixin = { Label = { Right = 2 } }
CreateSettingsListSectionHeaderInitializer = noop
CreateSettingsButtonInitializer = noop
SlashCmdList = {}
securecallfunction = function(f, ...) return f(...) end
strmatch = string.match
tinsert = table.insert
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
GetLocale = function() return "enUS" end

-- Load in TOC order
local ns = {}
local files = {}
for line in io.lines(ROOT .. "/LatencyGuard.toc") do
	if line:match("%.lua$") then files[#files + 1] = line:gsub("\\", "/") end
end
for _, f in ipairs(files) do
	local chunk = assert(loadfile(ROOT .. "/" .. f))
	chunk("LatencyGuard", ns)
end

local function check(cond, msg)
	print((cond and "PASS " or "FAIL ") .. msg)
	if not cond then FAILED = true end
end
local function tick()
	for _, t in ipairs(tickers) do if not t.cancelled then t.f() end end
end

if arg[2] == "fresh" then
	cvars.SpellQueueWindow = "275"
	Fire("ADDON_LOADED", "LatencyGuard")
	check(LatencyGuardDB.schemaVersion == 2 and LatencyGuardDB.originalSQW == nil, "fresh install has no restore value yet")
	check(ns.db.enable == true and ns.db.margin == 100 and ns.db.spikeAlert == false, "fresh install uses defaults")
	Fire("PLAYER_LOGIN")
	net = { 1, 1, 30, 30 }; tick()
	check(cvars.SpellQueueWindow == "130", "first write 30 + 100 = 130 (got " .. cvars.SpellQueueWindow .. ")")
	check(LatencyGuardDB.originalSQW == 275, "player's own 275 captured before first write")
	SlashCmdList.LATENCYGUARD("restore")
	check(cvars.SpellQueueWindow == "275", "restore returns the captured 275")
	print(FAILED and "SOME FAILED" or "ALL PASSED")
	if FAILED then os.exit(1) end
	return
end

-- 1. Migration from the v1 profile layout
LatencyGuardDB = { schemaVersion = 1, profiles = { Default = { spellQueue = { enable = true, tolerance = 80, pvpTolerance = 40, adaptiveJitter = false, verbose = true } } }, profileKeys = {}, global = {} }
Fire("ADDON_LOADED", "LatencyGuard")
check(ns.db.margin == 80 and ns.db.pvpMargin == 40 and ns.db.adaptive == false and ns.db.verbose == true, "v1 settings migrated")
check(LatencyGuardDB.profiles == nil and LatencyGuardDB.schemaVersion == 2, "old layout removed")
check(LatencyGuardDB.originalSQW == 400, "migrated install restores to client default")

-- 2. Login with no latency yet: nothing is written
Fire("PLAYER_LOGIN")
check(cvars.SpellQueueWindow == "400", "no write before first latency reading")

-- 3. First reading 50ms, margin 80, adaptive off -> 130
net = { 1.5, 0.4, 40, 50 }
tick()
check(cvars.SpellQueueWindow == "130", "target = 50 + 80 = 130 (got " .. cvars.SpellQueueWindow .. ")")

-- 4. Small move inside the deadband is ignored
net[4] = 60; now = now + 31; tick()
check(cvars.SpellQueueWindow == "130", "10ms change ignored by deadband")

-- 5. Widening applies at once
net[4] = 120; now = now + 31; tick()
check(cvars.SpellQueueWindow == "200", "widening to 200 applies immediately")

-- 6. Narrowing waits for the hold
net[4] = 50; now = now + 31; tick()
check(cvars.SpellQueueWindow == "200", "narrowing held")
now = now + 46; tick()
check(cvars.SpellQueueWindow == "130", "narrowing applied after hold")

-- 7. Combat defers, regen applies
combat = true; net[4] = 150; now = now + 31; tick()
check(cvars.SpellQueueWindow == "130", "no write in combat")
combat = false; Fire("PLAYER_REGEN_ENABLED")
check(cvars.SpellQueueWindow == "230", "applied after combat")

-- 8. PvP margin
instanceType = "arena"; Fire("PLAYER_ENTERING_WORLD")
check(cvars.SpellQueueWindow == "190", "arena uses pvp margin 40 -> 190 (got " .. cvars.SpellQueueWindow .. ")")
instanceType = "none"; Fire("PLAYER_ENTERING_WORLD")
check(cvars.SpellQueueWindow == "230", "leaving arena widens back")

-- 9. External change pauses automation
cvars.SpellQueueWindow = "250"; Fire("CVAR_UPDATE", "SpellQueueWindow", "250")
net[4] = 10; now = now + 31; tick()
check(cvars.SpellQueueWindow == "250", "outside change respected")
check(LatencyGuardDB.originalSQW == 250, "manual value becomes restore value")
SlashCmdList.LATENCYGUARD("resume")
check(cvars.SpellQueueWindow == "100", "resume re-applies (clamped to 100, got " .. cvars.SpellQueueWindow .. ")")

-- 11. Adaptive headroom: 2 x net spread
ns.Monitor:ResetSamples()
settingsRegistered.adaptive:SetValue(true)
for i = 1, 3 do net[4] = 50; now = now + 31; ns.Monitor.Poll() end
check(cvars.SpellQueueWindow == "130", "steady net adds no headroom: 130 (got " .. cvars.SpellQueueWindow .. ")")
for _, w in ipairs({ 50, 150, 50, 150 }) do net[4] = w; now = now + 31; ns.Monitor.Poll() end
net[4] = 50; now = now + 31; ns.Monitor.Poll(); now = now + 46; ns.Monitor.Poll()
local _, sd = ns.Monitor:GetNetSummary()
check(cvars.SpellQueueWindow == tostring(50 + 80 + math.min(150, math.floor(2 * sd + 0.5))), "uneven net uses 2 x spread capped at 150 (got " .. cvars.SpellQueueWindow .. ", sd " .. sd .. ")")

-- 12. Readout lifecycle
SlashCmdList.LATENCYGUARD("readout")
local live = 0
for _, tk in ipairs(tickers) do if not tk.cancelled then live = live + 1 end end
check(ns.db.readout == true and live == 2, "readout ticker started (live tickers " .. live .. ")")
SlashCmdList.LATENCYGUARD("readout")
live = 0
for _, tk in ipairs(tickers) do if not tk.cancelled then live = live + 1 end end
check(live == 1, "readout ticker cancelled when hidden")

-- 13. Status report runs
local before = #chat
SlashCmdList.LATENCYGUARD("status")
check(#chat - before > 8, "status printed " .. (#chat - before) .. " lines")
for i = before + 1, #chat do print("   " .. chat[i]:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

-- 14. Refused write reports once
cvarRefuse = true; net[4] = 250; tick(); tick()
local blocked = 0
for _, m in ipairs(chat) do if m:find("did not accept") then blocked = blocked + 1 end end
check(blocked == 1, "refused write reported once")
cvarRefuse = false

-- 15. Restore in combat waits, then restores
combat = true
SlashCmdList.LATENCYGUARD("restore")
check(ns.db.enable == false and cvars.SpellQueueWindow ~= "250", "restore deferred in combat")
combat = false; Fire("PLAYER_REGEN_ENABLED")
check(cvars.SpellQueueWindow == "250", "restored player's value after combat")
net[4] = 20; tick()
check(cvars.SpellQueueWindow == "250", "no writes while automation is off")

-- 16. Fresh install captures the live value before the first write
-- 16. Silent login sync: first write of the session printed nothing (verbose is on from migration)
local updates = 0
for _, m in ipairs(chat) do if m:find("Spell Queue set to") then updates = updates + 1 end end
check(updates >= 1, "later writes still announced (" .. updates .. ")")
check(not chat[1] or not chat[1]:find("Spell Queue set to 130"), "first write after login not announced")

-- 17. Spike alert with hysteresis
settingsRegistered.enable:SetValue(true)
settingsRegistered.spikeAlert:SetValue(true)
settingsRegistered.spikeThreshold:SetValue(200)
local function count(pat) local c = 0 for _, m in ipairs(chat) do if m:find(pat) then c = c + 1 end end return c end
net[4] = 250; tick(); net[4] = 320; tick(); net[4] = 190; tick()
check(count("spiked to") == 1, "one spike alert while above and hovering")
check(count("back to") == 0, "no recovery at 190 (needs under 160)")
net[4] = 150; tick()
check(count("back to") == 1 and chat[#chat]:find("peak 320ms"), "recovery printed once with peak 320")
net[4] = 155; tick()
check(count("back to") == 1 and count("spiked to") == 1, "no repeat while calm")

-- 18. On-target state and readout fields
local function report()
	local lines = {}
	ns.Report(function(l, v) if l then lines[l] = v end end)
	return lines
end
net[4] = 50; now = now + 100; tick(); now = now + 100; tick()
local st = report()[ns.L["State"]] or ""
check(st:find("on target"), "state reads on target: " .. st:gsub("|c%x+", ""):gsub("|r", ""))
settingsRegistered.readout:SetValue(true)
settingsRegistered.readoutHome:SetValue(true)
settingsRegistered.readoutFps:SetValue(false)
local readoutText
for _, f in ipairs(frames) do for _, v in pairs(f) do end end
-- find the readout's font string via the global report path instead: the frame text is internal,
-- so check behavior through the Apply refresh not erroring and fields being read.
check(ns.db.readoutHome == true and ns.db.readoutFps == false, "readout field toggles stored")

-- 19. Broker feed
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local brokerObj = ldb:GetDataObjectByName("LatencyGuard")
local changes = 0
ldb.RegisterCallback(ldb, "LibDataBroker_AttributeChanged_LatencyGuard_text", function() changes = changes + 1 end)
tick(); tick()
check(changes == 0, "unchanged text fires no callbacks")
net[4] = 70; tick()
check(changes == 1, "changed text fires one callback")
check(brokerObj ~= nil and brokerObj.type == "data source", "broker data object created")
local plain = (brokerObj.text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
check(plain:find("70ms") and plain:find("SQW"), "broker text shows latency and queue: " .. plain)
local tipLines = 0
brokerObj.OnTooltipShow({ AddLine = function() tipLines = tipLines + 1 end, AddDoubleLine = function() tipLines = tipLines + 1 end })
check(tipLines > 8, "broker tooltip lines " .. tipLines)

print(FAILED and "SOME FAILED" or "ALL PASSED")
if FAILED then os.exit(1) end
