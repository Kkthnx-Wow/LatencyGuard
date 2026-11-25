--[[
	LatencyGuard - Stats
	Fixed-size numeric ring buffer with mean, spread and percentiles.
	Storage never grows past its capacity. Percentiles sort into one scratch
	table owned by the ring, so a query allocates nothing after warm-up.
--]]

local _, ns = ...

local setmetatable = setmetatable
local sqrt = math.sqrt
local ceil = math.ceil
local sort = table.sort

local Ring = {}
Ring.__index = Ring

function ns.NewRing(capacity)
	return setmetatable({ capacity = capacity, count = 0, head = 0, values = {}, scratch = {} }, Ring)
end

function Ring:Push(value)
	local head = self.head % self.capacity + 1
	self.head = head
	self.values[head] = value
	if self.count < self.capacity then
		self.count = self.count + 1
	end
	self.dirty = true
end

function Ring:Clear()
	self.count = 0
	self.head = 0
	self.dirty = true
end

function Ring:Count()
	return self.count
end

function Ring:Last()
	if self.count == 0 then
		return nil
	end
	return self.values[self.head]
end

--- Mean, population standard deviation, min and max. Nil when empty.
function Ring:Summary()
	local n = self.count
	if n == 0 then
		return nil
	end
	local values = self.values
	local sum, low, high = 0, values[1], values[1]
	for i = 1, n do
		local v = values[i]
		sum = sum + v
		if v < low then
			low = v
		end
		if v > high then
			high = v
		end
	end
	local mean = sum / n
	local var = 0
	for i = 1, n do
		local d = values[i] - mean
		var = var + d * d
	end
	return mean, sqrt(var / n), low, high
end

--- Nearest-rank percentile, p in 0..1. Nil when empty.
function Ring:Percentile(p)
	local n = self.count
	if n == 0 then
		return nil
	end
	local scratch = self.scratch
	if self.dirty then
		-- Only the first `n` slots are live, so stale tail entries are cleared.
		for i = 1, n do
			scratch[i] = self.values[i]
		end
		for i = n + 1, #scratch do
			scratch[i] = nil
		end
		sort(scratch)
		self.dirty = false
	end
	local rank = ceil(p * n)
	if rank < 1 then
		rank = 1
	end
	return scratch[rank]
end
