--[[
	LatencyGuard - Functions
	-------------------------------------------------------------------------
	Shared utility library. Stateless helpers with file-scope global caching
	for anything that might run on a timer or event path.
--]]

local _, ns = ...
local C, F = ns.C, ns.F

local select, type, tostring = select, type, tostring
local pairs = pairs
local floor = math.floor
local format = string.format
local tconcat = table.concat
local wipe = wipe
local C_Timer = C_Timer
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME

local PREFIX = format("|c%s%s|r:", C.BrandHex, "LatencyGuard")

local printBuffer = {}

function F.Print(...)
	wipe(printBuffer)
	printBuffer[1] = PREFIX
	for i = 1, select("#", ...) do
		printBuffer[i + 1] = tostring((select(i, ...)))
	end
	DEFAULT_CHAT_FRAME:AddMessage(tconcat(printBuffer, " "))
end

function F.RGBToHex(r, g, b)
	if type(r) == "table" then
		r, g, b = r[1], r[2], r[3]
	end
	return format("ff%02x%02x%02x", r * 255, g * 255, b * 255)
end

function F.Colorize(text, color)
	if type(color) == "string" then
		color = C.Colors[color] or C.Colors.white
	end
	return format("|c%s%s|r", F.RGBToHex(color), text)
end

function F.Round(value, places)
	if places and places > 0 then
		local mult = 10 ^ places
		return floor(value * mult + 0.5) / mult
	end
	return floor(value + 0.5)
end

function F.CopyDefaults(defaults, target)
	if type(target) ~= "table" then
		target = {}
	end
	for key, value in pairs(defaults) do
		if type(value) == "table" then
			target[key] = F.CopyDefaults(value, target[key])
		elseif target[key] == nil or type(target[key]) ~= type(value) then
			target[key] = value
		end
	end
	return target
end

function F.Debounce(delay, func)
	local scheduled = false
	return function(...)
		if scheduled then
			return
		end
		scheduled = true
		local args = { ... }
		C_Timer.After(delay, function()
			scheduled = false
			func(unpack(args))
		end)
	end
end

-- ---------------------------------------------------------------------------
-- Midnight Secret Values
-- ---------------------------------------------------------------------------
do
	local issecretvalue = issecretvalue
	local canaccessvalue = canaccessvalue

	function F.IsSecret(value)
		return issecretvalue and issecretvalue(value)
	end

	function F.NotSecret(value)
		return not F.IsSecret(value)
	end

	function F.CanAccessValue(value)
		return not canaccessvalue or canaccessvalue(value)
	end

	function F.CanNotAccessValue(value)
		return not F.CanAccessValue(value)
	end
end
