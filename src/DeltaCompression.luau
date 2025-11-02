--!strict
--!native
--!optimize 2
-- Ligaya Framework - Delta Compression
-- Efficient encoding of changes between states

local DeltaCompression = {}
DeltaCompression.__index = DeltaCompression

-- Delta encoding flags
local DELTA_FULL = 0 -- Full state
local DELTA_PARTIAL = 1 -- Only changed fields

function DeltaCompression.new()
	local self = setmetatable({}, DeltaCompression)

	-- Store last sent state per entity
	self._lastStates = {}
	self._stateTimeout = 5.0 -- Reset after 5 seconds of no updates
	self._lastUpdateTime = {}

	return self
end

-- Encode Vector3 delta (position)
function DeltaCompression:EncodeVector3Delta(buf: buffer, cursor: number, current: Vector3, last: Vector3?): number
	if not last then
		-- Full state
		buffer.writeu8(buf, cursor, DELTA_FULL)
		buffer.writef32(buf, cursor + 1, current.X)
		buffer.writef32(buf, cursor + 5, current.Y)
		buffer.writef32(buf, cursor + 9, current.Z)
		return cursor + 13
	end

	-- Calculate delta
	local dx = current.X - last.X
	local dy = current.Y - last.Y
	local dz = current.Z - last.Z

	-- Check if delta is small enough to encode as i16 (range: -32768 to 32767)
	-- Scale by 100 for 2 decimal precision
	local canUseDelta = math.abs(dx) < 327 and math.abs(dy) < 327 and math.abs(dz) < 327

	if canUseDelta then
		-- Delta state (much smaller)
		buffer.writeu8(buf, cursor, DELTA_PARTIAL)
		buffer.writei16(buf, cursor + 1, math.floor(dx * 100))
		buffer.writei16(buf, cursor + 3, math.floor(dy * 100))
		buffer.writei16(buf, cursor + 5, math.floor(dz * 100))
		return cursor + 7 -- Saved 6 bytes!
	else
		-- Delta too large, send full state
		buffer.writeu8(buf, cursor, DELTA_FULL)
		buffer.writef32(buf, cursor + 1, current.X)
		buffer.writef32(buf, cursor + 5, current.Y)
		buffer.writef32(buf, cursor + 9, current.Z)
		return cursor + 13
	end
end

-- Decode Vector3 delta
function DeltaCompression:DecodeVector3Delta(buf: buffer, cursor: number, last: Vector3?): (Vector3, number)
	local deltaType = buffer.readu8(buf, cursor)
	cursor += 1

	if deltaType == DELTA_FULL then
		-- Full state
		local x = buffer.readf32(buf, cursor)
		local y = buffer.readf32(buf, cursor + 4)
		local z = buffer.readf32(buf, cursor + 8)
		return Vector3.new(x, y, z), cursor + 12
	else
		-- Delta state
		if not last then
			warn("[DeltaCompression] Received delta without previous state")
			return Vector3.zero, cursor + 6
		end

		local dx = buffer.readi16(buf, cursor) / 100
		local dy = buffer.readi16(buf, cursor + 2) / 100
		local dz = buffer.readi16(buf, cursor + 4) / 100

		return Vector3.new(last.X + dx, last.Y + dy, last.Z + dz), cursor + 6
	end
end

-- Encode CFrame delta (position + rotation)
function DeltaCompression:EncodeCFrameDelta(buf: buffer, cursor: number, current: CFrame, last: CFrame?): number
	if not last then
		-- Full state
		buffer.writeu8(buf, cursor, DELTA_FULL)
		local pos = current.Position
		buffer.writef32(buf, cursor + 1, pos.X)
		buffer.writef32(buf, cursor + 5, pos.Y)
		buffer.writef32(buf, cursor + 9, pos.Z)

		local rx, ry, rz = current:ToOrientation()
		buffer.writef32(buf, cursor + 13, rx)
		buffer.writef32(buf, cursor + 17, ry)
		buffer.writef32(buf, cursor + 21, rz)
		return cursor + 25
	end

	-- Calculate position delta
	local pos = current.Position
	local lastPos = last.Position
	local dx = pos.X - lastPos.X
	local dy = pos.Y - lastPos.Y
	local dz = pos.Z - lastPos.Z

	-- Calculate rotation delta
	local rx, ry, rz = current:ToOrientation()
	local lrx, lry, lrz = last:ToOrientation()
	local drx = rx - lrx
	local dry = ry - lry
	local drz = rz - lrz

	-- Check if deltas are small enough
	local canUseDelta = math.abs(dx) < 327
		and math.abs(dy) < 327
		and math.abs(dz) < 327
		and math.abs(drx) < 3.27
		and math.abs(dry) < 3.27
		and math.abs(drz) < 3.27

	if canUseDelta then
		-- Delta state
		buffer.writeu8(buf, cursor, DELTA_PARTIAL)
		buffer.writei16(buf, cursor + 1, math.floor(dx * 100))
		buffer.writei16(buf, cursor + 3, math.floor(dy * 100))
		buffer.writei16(buf, cursor + 5, math.floor(dz * 100))
		buffer.writei16(buf, cursor + 7, math.floor(drx * 1000))
		buffer.writei16(buf, cursor + 9, math.floor(dry * 1000))
		buffer.writei16(buf, cursor + 11, math.floor(drz * 1000))
		return cursor + 13 -- Saved 12 bytes!
	else
		-- Delta too large, send full state
		buffer.writeu8(buf, cursor, DELTA_FULL)
		buffer.writef32(buf, cursor + 1, pos.X)
		buffer.writef32(buf, cursor + 5, pos.Y)
		buffer.writef32(buf, cursor + 9, pos.Z)
		buffer.writef32(buf, cursor + 13, rx)
		buffer.writef32(buf, cursor + 17, ry)
		buffer.writef32(buf, cursor + 21, rz)
		return cursor + 25
	end
end

-- Decode CFrame delta
function DeltaCompression:DecodeCFrameDelta(buf: buffer, cursor: number, last: CFrame?): (CFrame, number)
	local deltaType = buffer.readu8(buf, cursor)
	cursor += 1

	if deltaType == DELTA_FULL then
		-- Full state
		local px = buffer.readf32(buf, cursor)
		local py = buffer.readf32(buf, cursor + 4)
		local pz = buffer.readf32(buf, cursor + 8)
		local rx = buffer.readf32(buf, cursor + 12)
		local ry = buffer.readf32(buf, cursor + 16)
		local rz = buffer.readf32(buf, cursor + 20)
		return CFrame.new(px, py, pz) * CFrame.fromOrientation(rx, ry, rz), cursor + 24
	else
		-- Delta state
		if not last then
			warn("[DeltaCompression] Received delta without previous state")
			return CFrame.identity, cursor + 12
		end

		local lastPos = last.Position
		local dx = buffer.readi16(buf, cursor) / 100
		local dy = buffer.readi16(buf, cursor + 2) / 100
		local dz = buffer.readi16(buf, cursor + 4) / 100

		local lrx, lry, lrz = last:ToOrientation()
		local drx = buffer.readi16(buf, cursor + 6) / 1000
		local dry = buffer.readi16(buf, cursor + 8) / 1000
		local drz = buffer.readi16(buf, cursor + 10) / 1000

		local newPos = Vector3.new(lastPos.X + dx, lastPos.Y + dy, lastPos.Z + dz)
		return CFrame.new(newPos) * CFrame.fromOrientation(lrx + drx, lry + dry, lrz + drz), cursor + 12
	end
end

-- Store state for entity
function DeltaCompression:StoreState(entityId: string, state: any)
	self._lastStates[entityId] = state
	self._lastUpdateTime[entityId] = os.clock()
end

-- Get last state for entity
function DeltaCompression:GetLastState(entityId: string): any?
	local lastTime = self._lastUpdateTime[entityId]
	if lastTime and (os.clock() - lastTime) > self._stateTimeout then
		-- State too old, clear it
		self._lastStates[entityId] = nil
		self._lastUpdateTime[entityId] = nil
		return nil
	end

	return self._lastStates[entityId]
end

-- Clear state for entity
function DeltaCompression:ClearState(entityId: string)
	self._lastStates[entityId] = nil
	self._lastUpdateTime[entityId] = nil
end

-- Clear all states
function DeltaCompression:ClearAll()
	table.clear(self._lastStates)
	table.clear(self._lastUpdateTime)
end

-- Get compression statistics
function DeltaCompression:GetStats()
	local totalStates = 0
	local activeStates = 0
	local currentTime = os.clock()

	for entityId, lastTime in pairs(self._lastUpdateTime) do
		totalStates += 1
		if (currentTime - lastTime) <= self._stateTimeout then
			activeStates += 1
		end
	end

	return {
		TotalStates = totalStates,
		ActiveStates = activeStates,
		StateTimeout = self._stateTimeout,
	}
end

return DeltaCompression
