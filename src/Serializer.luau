--!strict
-- Ligaya Framework - Data Serializer
-- Converts Lua data to/from buffer format

local HttpService = game:GetService("HttpService")

local Serializer = {}

-- Serialize data to buffer using JSON encoding
function Serializer.Serialize(data: any): buffer
	-- Convert to JSON string
	local jsonString = HttpService:JSONEncode(data)
	local stringBytes = buffer.fromstring(jsonString)

	-- Create buffer with size prefix (4 bytes for u32)
	local dataSize = buffer.len(stringBytes)
	local resultBuffer = buffer.create(dataSize + 4)

	-- Write size prefix
	buffer.writeu32(resultBuffer, 0, dataSize)

	-- Write data
	buffer.copy(resultBuffer, 4, stringBytes, 0, dataSize)

	return resultBuffer
end

-- Deserialize buffer back to Lua data
function Serializer.Deserialize(buf: buffer, offset: number?): (any, number)
	local startOffset = offset or 0

	-- Read size prefix
	local dataSize = buffer.readu32(buf, startOffset)

	-- Read data bytes
	local dataBuffer = buffer.create(dataSize)
	buffer.copy(dataBuffer, 0, buf, startOffset + 4, dataSize)

	-- Convert to string and decode JSON
	local jsonString = buffer.tostring(dataBuffer)
	local data = HttpService:JSONDecode(jsonString)

	-- Return data and new offset
	return data, startOffset + 4 + dataSize
end

-- Write event to buffer (event index + data)
function Serializer.WriteEvent(targetBuffer: buffer, cursor: number, eventIndex: number, data: any): number
	-- Write event index (2 bytes)
	buffer.writeu16(targetBuffer, cursor, eventIndex)
	local newCursor = cursor + 2

	-- Serialize and write data
	local dataBuffer = Serializer.Serialize(data)
	local dataSize = buffer.len(dataBuffer)

	-- Copy serialized data
	buffer.copy(targetBuffer, newCursor, dataBuffer, 0, dataSize)

	return newCursor + dataSize
end

-- Read event from buffer
function Serializer.ReadEvent(sourceBuffer: buffer, cursor: number): (number, any, number)
	-- Read event index
	local eventIndex = buffer.readu16(sourceBuffer, cursor)
	local newCursor = cursor + 2

	-- Deserialize data
	local data, finalCursor = Serializer.Deserialize(sourceBuffer, newCursor)

	return eventIndex, data, finalCursor
end

return Serializer
