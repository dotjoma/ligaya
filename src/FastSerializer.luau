--!strict
--!native
--!optimize 2
-- Ligaya Framework - Fast Direct Buffer Serializer
-- High-performance serialization without JSON overhead

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
		-- Check if it's an array
		local isArray = true
		local count = 0
		for k, _ in pairs(value) do
			count += 1
			if type(k) ~= "number" or k ~= count then
				isArray = false
				break
			end
		end

		if isArray then
			buffer.writeu8(buf, cursor, TYPE_ARRAY)
			buffer.writeu16(buf, cursor + 1, count)
			cursor = cursor + 3

			for i = 1, count do
				cursor = writeValue(buf, cursor, value[i], instances)
			end
		else
			buffer.writeu8(buf, cursor, TYPE_TABLE)
			buffer.writeu16(buf, cursor + 1, count)
			cursor = cursor + 3

			for k, v in pairs(value) do
				cursor = writeValue(buf, cursor, k, instances)
				cursor = writeValue(buf, cursor, v, instances)
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
		local count = buffer.readu16(buf, cursor)
		cursor += 2

		local tbl = {}
		for _ = 1, count do
			local key, newCursor = readValue(buf, cursor, instances)
			cursor = newCursor

			local value, newCursor2 = readValue(buf, cursor, instances)
			cursor = newCursor2

			tbl[key] = value
		end

		return tbl, cursor
	end

	warn(`[FastSerializer] Unknown type ID: {typeId}`)
	return nil, cursor
end

-- Serialize array of values
function FastSerializer.Serialize(buf: buffer, cursor: number, values: { any }, instances: { Instance }): number
	-- Write count
	buffer.writeu8(buf, cursor, #values)
	cursor += 1

	-- Write each value
	for _, value in values do
		cursor = writeValue(buf, cursor, value, instances)
	end

	return cursor
end

-- Deserialize array of values
function FastSerializer.Deserialize(buf: buffer, cursor: number, instances: { Instance }): ({ any }, number)
	-- Read count
	local count = buffer.readu8(buf, cursor)
	cursor += 1

	-- Read each value
	local values = table.create(count)
	for i = 1, count do
		local value, newCursor = readValue(buf, cursor, instances)
		values[i] = value
		cursor = newCursor
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
	-- Write event index (2 bytes)
	buffer.writeu16(targetBuffer, cursor, eventIndex)
	cursor += 2

	-- Serialize data
	cursor = FastSerializer.Serialize(targetBuffer, cursor, data, instances)

	return cursor
end

-- Read event from buffer
function FastSerializer.ReadEvent(
	sourceBuffer: buffer,
	cursor: number,
	instances: { Instance }
): (number, { any }, number)
	-- Read event index
	local eventIndex = buffer.readu16(sourceBuffer, cursor)
	cursor += 2

	-- Deserialize data
	local data, newCursor = FastSerializer.Deserialize(sourceBuffer, cursor, instances)

	return eventIndex, data, newCursor
end

return FastSerializer
