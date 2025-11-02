--!strict
--!native
--!optimize 2
-- Ligaya Framework - Fast Direct Buffer Serializer
-- High-performance serialization without JSON overhead

local Config = require(script.Parent.Config)

local FastSerializer = {}

-- Type identifiers (1 byte each)
local TYPE_NIL = 0
local TYPE_BOOLEAN = 1
local TYPE_NUMBER = 2
local TYPE_STRING = 3
local TYPE_VECTOR3 = 4
local TYPE_VECTOR2 = 5
local TYPE_CFRAME = 6
local TYPE_COLOR3 = 7
local TYPE_INSTANCE = 8
local TYPE_TABLE = 9
local TYPE_ARRAY = 10

-- Write a value directly to buffer
local function writeValue(buf: buffer, cursor: number, value: any, instances: { Instance }): number
	local valueType = typeof(value)

	if value == nil then
		buffer.writeu8(buf, cursor, TYPE_NIL)
		return cursor + 1
	elseif valueType == "boolean" then
		buffer.writeu8(buf, cursor, TYPE_BOOLEAN)
		buffer.writeu8(buf, cursor + 1, if value then 1 else 0)
		return cursor + 2
	elseif valueType == "number" then
		buffer.writeu8(buf, cursor, TYPE_NUMBER)
		buffer.writef64(buf, cursor + 1, value)
		return cursor + 9
	elseif valueType == "string" then
		buffer.writeu8(buf, cursor, TYPE_STRING)
		local len = #value
		buffer.writeu16(buf, cursor + 1, len)
		buffer.writestring(buf, cursor + 3, value)
		return cursor + 3 + len
	elseif valueType == "Vector3" then
		buffer.writeu8(buf, cursor, TYPE_VECTOR3)
		buffer.writef32(buf, cursor + 1, value.X)
		buffer.writef32(buf, cursor + 5, value.Y)
		buffer.writef32(buf, cursor + 9, value.Z)
		return cursor + 13
	elseif valueType == "Vector2" then
		buffer.writeu8(buf, cursor, TYPE_VECTOR2)
		buffer.writef32(buf, cursor + 1, value.X)
		buffer.writef32(buf, cursor + 5, value.Y)
		return cursor + 9
	elseif valueType == "CFrame" then
		buffer.writeu8(buf, cursor, TYPE_CFRAME)
		local pos = value.Position
		buffer.writef32(buf, cursor + 1, pos.X)
		buffer.writef32(buf, cursor + 5, pos.Y)
		buffer.writef32(buf, cursor + 9, pos.Z)

		local rx, ry, rz = value:ToOrientation()
		buffer.writef32(buf, cursor + 13, rx)
		buffer.writef32(buf, cursor + 17, ry)
		buffer.writef32(buf, cursor + 21, rz)
		return cursor + 25
	elseif valueType == "Color3" then
		buffer.writeu8(buf, cursor, TYPE_COLOR3)
		buffer.writef32(buf, cursor + 1, value.R)
		buffer.writef32(buf, cursor + 5, value.G)
		buffer.writef32(buf, cursor + 9, value.B)
		return cursor + 13
	elseif valueType == "Instance" then
		buffer.writeu8(buf, cursor, TYPE_INSTANCE)
		table.insert(instances, value)
		buffer.writeu16(buf, cursor + 1, #instances)
		return cursor + 3
	elseif valueType == "table" then
		-- Check if it's an array by checking if all keys are sequential numbers starting from 1
		local isArray = true
		local maxIndex = 0
		local count = 0

		for k, _ in pairs(value) do
			count += 1
			if isArray then -- Only check array properties if we haven't already determined it's not an array
				if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then
					isArray = false
				elseif k > maxIndex then
					maxIndex = k
				end
			end
		end

		-- Verify it's truly sequential (no gaps)
		if isArray and maxIndex ~= count then
			isArray = false
		end

		if isArray then
			buffer.writeu8(buf, cursor, TYPE_ARRAY)
			buffer.writeu16(buf, cursor + 1, count)
			cursor = cursor + 3

			for i = 1, count do
				cursor = writeValue(buf, cursor, value[i], instances)
			end
		else
			local startCursor = cursor
			buffer.writeu8(buf, cursor, TYPE_TABLE)
			buffer.writeu16(buf, cursor + 1, count)
			cursor = cursor + 3

			if Config.IsDebugEnabled("Serialization") then
				print(`[FastSerializer] writeValue TABLE: writing {count} key-value pairs`)
			end

			local pairIndex = 0
			for k, v in pairs(value) do
				pairIndex += 1
				local beforeKey = cursor
				cursor = writeValue(buf, cursor, k, instances)
				local beforeValue = cursor
				cursor = writeValue(buf, cursor, v, instances)

				if Config.IsDebugEnabled("BufferOperations") then
					print(
						`[FastSerializer] writeValue TABLE pair #{pairIndex}: key ({typeof(k)}) {cursor - beforeKey} bytes, value ({typeof(
							v
						)}) {cursor - beforeValue} bytes`
					)
				end
			end

			if Config.IsDebugEnabled("Serialization") then
				print(`[FastSerializer] writeValue TABLE: total {cursor - startCursor} bytes`)
			end
		end

		return cursor
	end

	-- Fallback: write as nil
	warn(`[FastSerializer] Unsupported type: {valueType}`)
	buffer.writeu8(buf, cursor, TYPE_NIL)
	return cursor + 1
end

-- Read a value from buffer
local function readValue(buf: buffer, cursor: number, instances: { Instance }): (any, number)
	local typeId = buffer.readu8(buf, cursor)
	cursor += 1

	if typeId == TYPE_NIL then
		return nil, cursor
	elseif typeId == TYPE_BOOLEAN then
		local value = buffer.readu8(buf, cursor) == 1
		return value, cursor + 1
	elseif typeId == TYPE_NUMBER then
		local value = buffer.readf64(buf, cursor)
		return value, cursor + 8
	elseif typeId == TYPE_STRING then
		local len = buffer.readu16(buf, cursor)
		local value = buffer.readstring(buf, cursor + 2, len)
		return value, cursor + 2 + len
	elseif typeId == TYPE_VECTOR3 then
		local x = buffer.readf32(buf, cursor)
		local y = buffer.readf32(buf, cursor + 4)
		local z = buffer.readf32(buf, cursor + 8)
		return Vector3.new(x, y, z), cursor + 12
	elseif typeId == TYPE_VECTOR2 then
		local x = buffer.readf32(buf, cursor)
		local y = buffer.readf32(buf, cursor + 4)
		return Vector2.new(x, y), cursor + 8
	elseif typeId == TYPE_CFRAME then
		local px = buffer.readf32(buf, cursor)
		local py = buffer.readf32(buf, cursor + 4)
		local pz = buffer.readf32(buf, cursor + 8)
		local rx = buffer.readf32(buf, cursor + 12)
		local ry = buffer.readf32(buf, cursor + 16)
		local rz = buffer.readf32(buf, cursor + 20)
		return CFrame.new(px, py, pz) * CFrame.fromOrientation(rx, ry, rz), cursor + 24
	elseif typeId == TYPE_COLOR3 then
		local r = buffer.readf32(buf, cursor)
		local g = buffer.readf32(buf, cursor + 4)
		local b = buffer.readf32(buf, cursor + 8)
		return Color3.new(r, g, b), cursor + 12
	elseif typeId == TYPE_INSTANCE then
		local index = buffer.readu16(buf, cursor)
		return instances[index], cursor + 2
	elseif typeId == TYPE_ARRAY then
		local count = buffer.readu16(buf, cursor)
		cursor += 2

		local array = table.create(count)
		for i = 1, count do
			local value, newCursor = readValue(buf, cursor, instances)
			array[i] = value
			cursor = newCursor
		end

		return array, cursor
	elseif typeId == TYPE_TABLE then
		local startCursor = cursor - 1 -- -1 because we already read the type byte
		local count = buffer.readu16(buf, cursor)
		cursor += 2

		if Config.IsDebugEnabled("Serialization") then
			print(`[FastSerializer] readValue TABLE: reading {count} key-value pairs`)
		end

		local tbl = {}
		for i = 1, count do
			local beforeKey = cursor
			local key, newCursor = readValue(buf, cursor, instances)
			cursor = newCursor

			local beforeValue = cursor
			local value, newCursor2 = readValue(buf, cursor, instances)
			cursor = newCursor2

			if Config.IsDebugEnabled("BufferOperations") then
				print(
					`[FastSerializer] readValue TABLE pair #{i}: key ({typeof(key)}) {cursor - beforeKey} bytes, value ({typeof(
						value
					)}) {cursor - beforeValue} bytes`
				)
			end

			tbl[key] = value
		end

		if Config.IsDebugEnabled("Serialization") then
			print(`[FastSerializer] readValue TABLE: total {cursor - startCursor} bytes`)
		end

		return tbl, cursor
	end

	warn(`[FastSerializer] Unknown type ID: {typeId}`)
	return nil, cursor
end

-- Serialize array of values
function FastSerializer.Serialize(buf: buffer, cursor: number, values: { any }, instances: { Instance }): number
	local startCursor = cursor

	-- Write count
	buffer.writeu8(buf, cursor, #values)
	cursor += 1

	if Config.IsDebugEnabled("Serialization") then
		print(`[FastSerializer] Serialize: writing {#values} values starting at cursor {startCursor}`)
	end

	-- Write each value
	for i, value in values do
		local beforeCursor = cursor
		cursor = writeValue(buf, cursor, value, instances)

		if Config.IsDebugEnabled("BufferOperations") then
			print(`[FastSerializer] Serialize: value #{i} ({typeof(value)}) wrote {cursor - beforeCursor} bytes`)
		end
	end

	if Config.IsDebugEnabled("Serialization") then
		print(`[FastSerializer] Serialize: total {cursor - startCursor} bytes written`)
	end

	return cursor
end

-- Deserialize array of values
function FastSerializer.Deserialize(buf: buffer, cursor: number, instances: { Instance }): ({ any }, number)
	local startCursor = cursor

	-- Read count
	local count = buffer.readu8(buf, cursor)
	cursor += 1

	if Config.IsDebugEnabled("Serialization") then
		print(`[FastSerializer] Deserialize: reading {count} values starting at cursor {startCursor}`)
	end

	-- Read each value
	local values = table.create(count)
	for i = 1, count do
		local beforeCursor = cursor
		local value, newCursor = readValue(buf, cursor, instances)
		values[i] = value
		cursor = newCursor

		if Config.IsDebugEnabled("BufferOperations") then
			print(`[FastSerializer] Deserialize: value #{i} ({typeof(value)}) read {cursor - beforeCursor} bytes`)
		end
	end

	if Config.IsDebugEnabled("Serialization") then
		print(`[FastSerializer] Deserialize: total {cursor - startCursor} bytes read`)
	end

	return values, cursor
end

-- Write event to buffer (event index + data)
function FastSerializer.WriteEvent(
	targetBuffer: buffer,
	cursor: number,
	eventIndex: number,
	data: { any },
	instances: { Instance }
): number
	local startCursor = cursor

	-- Write event index (2 bytes)
	buffer.writeu16(targetBuffer, cursor, eventIndex)
	cursor += 2

	if Config.IsDebugEnabled("Events") then
		print(`[FastSerializer] WriteEvent: eventIndex={eventIndex}, cursor after index={cursor}`)
	end

	-- Serialize data
	cursor = FastSerializer.Serialize(targetBuffer, cursor, data, instances)

	if Config.IsDebugEnabled("Events") then
		print(
			`[FastSerializer] WriteEvent: serialized {#data} args, cursor: {startCursor} -> {cursor}, total bytes: {cursor - startCursor}`
		)
	end

	return cursor
end

-- Read event from buffer
function FastSerializer.ReadEvent(
	sourceBuffer: buffer,
	cursor: number,
	instances: { Instance }
): (number, { any }, number)
	local startCursor = cursor

	-- Read event index
	local eventIndex = buffer.readu16(sourceBuffer, cursor)
	cursor += 2

	if Config.IsDebugEnabled("Events") then
		print(`[FastSerializer] ReadEvent: eventIndex={eventIndex}, cursor after index={cursor}`)
	end

	-- Deserialize data
	local data, newCursor = FastSerializer.Deserialize(sourceBuffer, cursor, instances)

	if Config.IsDebugEnabled("Events") then
		print(
			`[FastSerializer] ReadEvent: deserialized {#data} args, cursor: {cursor} -> {newCursor}, total bytes: {newCursor - startCursor}`
		)
	end

	return eventIndex, data, newCursor
end

return FastSerializer
