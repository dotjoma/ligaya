--!strict
-- Ligaya Framework - Buffer Pool Implementation
-- Object pooling pattern for efficient buffer management

local Types = require(script.Parent.Types)

type BufferPool = Types.BufferPool
type BufferPoolStats = Types.BufferPoolStats

local DEFAULT_POOL_SIZE = 32
local DEFAULT_BUFFER_SIZE = 1024

local BufferPool = {}
BufferPool.__index = BufferPool

function BufferPool.new(initialSize: number?, bufferSize: number?): BufferPool
	local self = setmetatable({}, BufferPool)

	self._poolSize = initialSize or DEFAULT_POOL_SIZE
	self._bufferSize = bufferSize or DEFAULT_BUFFER_SIZE
	self._available = {}
	self._active = {}

	-- Stats tracking
	self._stats = {
		TotalBuffers = 0,
		ActiveBuffers = 0,
		PoolHits = 0,
		PoolMisses = 0,
	}

	-- Pre-allocate buffers
	for i = 1, self._poolSize do
		local buf = buffer.create(self._bufferSize)
		table.insert(self._available, buf)
		self._stats.TotalBuffers += 1
	end

	return self :: any
end

function BufferPool:Acquire(size: number): buffer
	local buf

	-- Try to get from pool
	if #self._available > 0 and size <= self._bufferSize then
		buf = table.remove(self._available)
		self._stats.PoolHits += 1
	else
		-- Create new buffer if pool is empty or size exceeds default
		buf = buffer.create(math.max(size, self._bufferSize))
		self._stats.TotalBuffers += 1
		self._stats.PoolMisses += 1
	end

	self._active[buf] = true
	self._stats.ActiveBuffers += 1

	return buf
end

function BufferPool:Release(buf: buffer)
	if not self._active[buf] then
		warn("[Ligaya] Attempting to release buffer not from this pool")
		return
	end

	self._active[buf] = nil
	self._stats.ActiveBuffers -= 1

	-- Only return to pool if it's the standard size
	if buffer.len(buf) == self._bufferSize then
		-- Clear buffer before returning to pool (fill with 0 from start to end)
		buffer.fill(buf, 0, 0, buffer.len(buf))
		table.insert(self._available, buf)
	else
		-- Let GC handle oversized buffers
		self._stats.TotalBuffers -= 1
	end
end

function BufferPool:Clear()
	table.clear(self._available)
	table.clear(self._active)

	-- Reset and recreate pool
	for i = 1, self._poolSize do
		local buf = buffer.create(self._bufferSize)
		table.insert(self._available, buf)
	end

	self._stats.TotalBuffers = self._poolSize
	self._stats.ActiveBuffers = 0
end

function BufferPool:GetStats(): BufferPoolStats
	return table.clone(self._stats)
end

return BufferPool
