--!strict
-- Ligaya Framework - Advanced Compression Strategy
-- Multiple algorithms with adaptive selection

local Types = require(script.Parent.Types)

type CompressionStrategy = Types.CompressionStrategy

-- Compression Algorithm Types
local CompressionType = {
	None = 0,
	RLE = 1,
	LZ77 = 2, -- LZ4-style compression
}

--[=[
	RLE Compression with Adaptive Threshold
	Best for: Repetitive data (99% savings possible)
]=]
local RLECompression = {}
RLECompression.__index = RLECompression

function RLECompression.new(threshold: number?): CompressionStrategy
	local self = setmetatable({}, RLECompression)
	self._threshold = threshold or 512
	self._minSavings = 0.1 -- 10% minimum savings
	return self :: any
end

function RLECompression:ShouldCompress(size: number): boolean
	return size >= self._threshold
end

function RLECompression:Compress(data: buffer): buffer
	local size = buffer.len(data)
	local compressed = buffer.create(size * 2 + 1)
	local writePos = 1 -- Reserve byte 0 for compression type
	local readPos = 0

	while readPos < size do
		local value = buffer.readu8(data, readPos)
		local count = 1

		while readPos + count < size and count < 255 do
			if buffer.readu8(data, readPos + count) == value then
				count += 1
			else
				break
			end
		end

		buffer.writeu8(compressed, writePos, count)
		buffer.writeu8(compressed, writePos + 1, value)
		writePos += 2
		readPos += count
	end

	-- Check if compression helped
	local compressionRatio = writePos / size
	if compressionRatio >= (1 - self._minSavings) then
		-- Not worth it, return original with None flag
		local result = buffer.create(size + 1)
		buffer.writeu8(result, 0, CompressionType.None)
		buffer.copy(result, 1, data, 0, size)
		return result
	end

	-- Compression helped, add RLE flag
	local result = buffer.create(writePos)
	buffer.writeu8(result, 0, CompressionType.RLE)
	buffer.copy(result, 1, compressed, 1, writePos - 1)

	return result
end

function RLECompression:Decompress(data: buffer): buffer
	local size = buffer.len(data)
	if size == 0 then
		return buffer.create(0)
	end

	-- Check compression type
	local compressionType = buffer.readu8(data, 0)

	if compressionType == CompressionType.None then
		-- No compression, return original
		local result = buffer.create(size - 1)
		buffer.copy(result, 0, data, 1, size - 1)
		return result
	end

	-- RLE decompression
	-- First pass: calculate size
	local decompressedSize = 0
	local pos = 1
	while pos < size do
		local count = buffer.readu8(data, pos)
		decompressedSize += count
		pos += 2
	end

	-- Second pass: decompress
	local decompressed = buffer.create(decompressedSize)
	local writePos = 0
	pos = 1

	while pos < size do
		local count = buffer.readu8(data, pos)
		local value = buffer.readu8(data, pos + 1)

		for i = 1, count do
			buffer.writeu8(decompressed, writePos, value)
			writePos += 1
		end

		pos += 2
	end

	return decompressed
end

--[=[
	LZ77-style Compression (Simplified LZ4)
	Best for: Structured data with patterns (30-50% savings)
]=]
local LZ77Compression = {}
LZ77Compression.__index = LZ77Compression

function LZ77Compression.new(threshold: number?): CompressionStrategy
	local self = setmetatable({}, LZ77Compression)
	self._threshold = threshold or 512
	self._minSavings = 0.1
	self._windowSize = 4096 -- Look-back window
	self._minMatch = 4 -- Minimum match length
	return self :: any
end

function LZ77Compression:ShouldCompress(size: number): boolean
	return size >= self._threshold
end

function LZ77Compression:Compress(data: buffer): buffer
	local size = buffer.len(data)
	local compressed = buffer.create(size * 2 + 1)
	local writePos = 1
	local readPos = 0

	buffer.writeu8(compressed, 0, CompressionType.LZ77)

	while readPos < size do
		local bestMatchLen = 0
		local bestMatchDist = 0

		-- Search for matches in the window
		local windowStart = math.max(0, readPos - self._windowSize)

		for i = windowStart, readPos - 1 do
			local matchLen = 0

			while
				matchLen < 255
				and readPos + matchLen < size
				and buffer.readu8(data, i + matchLen) == buffer.readu8(data, readPos + matchLen)
			do
				matchLen += 1
			end

			if matchLen >= self._minMatch and matchLen > bestMatchLen then
				bestMatchLen = matchLen
				bestMatchDist = readPos - i
			end
		end

		if bestMatchLen >= self._minMatch then
			-- Write match: [1 bit flag][distance][length]
			buffer.writeu8(compressed, writePos, 1) -- Match flag
			buffer.writeu16(compressed, writePos + 1, bestMatchDist)
			buffer.writeu8(compressed, writePos + 3, bestMatchLen)
			writePos += 4
			readPos += bestMatchLen
		else
			-- Write literal: [0 bit flag][byte]
			buffer.writeu8(compressed, writePos, 0) -- Literal flag
			buffer.writeu8(compressed, writePos + 1, buffer.readu8(data, readPos))
			writePos += 2
			readPos += 1
		end
	end

	-- Check if compression helped
	if writePos >= size * (1 - self._minSavings) then
		local result = buffer.create(size + 1)
		buffer.writeu8(result, 0, CompressionType.None)
		buffer.copy(result, 1, data, 0, size)
		return result
	end

	local result = buffer.create(writePos)
	buffer.copy(result, 0, compressed, 0, writePos)
	return result
end

function LZ77Compression:Decompress(data: buffer): buffer
	local size = buffer.len(data)
	if size == 0 then
		return buffer.create(0)
	end

	local compressionType = buffer.readu8(data, 0)

	if compressionType == CompressionType.None then
		local result = buffer.create(size - 1)
		buffer.copy(result, 0, data, 1, size - 1)
		return result
	end

	-- LZ77 decompression
	-- Use larger estimate for highly repetitive data
	local decompressed = buffer.create(math.max(size * 8, 8192))
	local writePos = 0
	local readPos = 1

	while readPos < size do
		-- Check if we have at least 1 byte for the flag
		if readPos >= size then
			break
		end

		local flag = buffer.readu8(data, readPos)

		if flag == 1 then
			-- Match - need 4 bytes total (flag + distance + length)
			if readPos + 3 >= size then
				break
			end

			local distance = buffer.readu16(data, readPos + 1)
			local length = buffer.readu8(data, readPos + 3)
			readPos += 4

			-- Validate copyFrom position
			if distance > writePos or distance == 0 then
				-- Invalid distance, skip this match
				continue
			end

			local copyFrom = writePos - distance

			-- Copy bytes one at a time (handles overlapping copies)
			for i = 1, length do
				if copyFrom >= 0 and copyFrom < writePos then
					buffer.writeu8(decompressed, writePos, buffer.readu8(decompressed, copyFrom))
					writePos += 1
					copyFrom += 1
				else
					break
				end
			end
		else
			-- Literal - need 2 bytes total (flag + byte)
			if readPos + 1 >= size then
				break
			end

			buffer.writeu8(decompressed, writePos, buffer.readu8(data, readPos + 1))
			writePos += 1
			readPos += 2
		end
	end

	-- Create final buffer with exact size
	if writePos == 0 then
		return buffer.create(0)
	end

	local result = buffer.create(writePos)
	buffer.copy(result, 0, decompressed, 0, writePos)
	return result
end

--[=[
	Adaptive Compression
	Automatically selects the best algorithm based on data characteristics
]=]
local AdaptiveCompression = {}
AdaptiveCompression.__index = AdaptiveCompression

function AdaptiveCompression.new(threshold: number?): CompressionStrategy
	local self = setmetatable({}, AdaptiveCompression)
	self._threshold = threshold or 512
	self._rle = RLECompression.new(threshold)
	self._lz77 = LZ77Compression.new(threshold)
	return self :: any
end

function AdaptiveCompression:ShouldCompress(size: number): boolean
	return size >= self._threshold
end

function AdaptiveCompression:Compress(data: buffer): buffer
	local size = buffer.len(data)

	-- Analyze data to choose best algorithm
	local repetitionScore = self:_analyzeRepetition(data)

	-- If highly repetitive, use RLE
	if repetitionScore > 0.5 then
		return self._rle:Compress(data)
	else
		-- Otherwise use LZ77 for structured data
		return self._lz77:Compress(data)
	end
end

function AdaptiveCompression:Decompress(data: buffer): buffer
	-- Decompress based on the compression type flag
	local compressionType = buffer.readu8(data, 0)

	if compressionType == CompressionType.None then
		local size = buffer.len(data)
		local result = buffer.create(size - 1)
		buffer.copy(result, 0, data, 1, size - 1)
		return result
	elseif compressionType == CompressionType.RLE then
		return self._rle:Decompress(data)
	else
		return self._lz77:Decompress(data)
	end
end

function AdaptiveCompression:_analyzeRepetition(data: buffer): number
	local size = buffer.len(data)
	if size == 0 then
		return 0
	end

	-- Sample the data to detect repetition
	local sampleSize = math.min(256, size)
	local repetitions = 0
	local lastValue = buffer.readu8(data, 0)

	for i = 1, sampleSize - 1 do
		local value = buffer.readu8(data, i)
		if value == lastValue then
			repetitions += 1
		end
		lastValue = value
	end

	return repetitions / sampleSize
end

-- No compression (pass-through)
local NoCompression = {}
NoCompression.__index = NoCompression

function NoCompression.new(): CompressionStrategy
	local self = setmetatable({}, NoCompression)
	return self :: any
end

function NoCompression:ShouldCompress(_size: number): boolean
	return false
end

function NoCompression:Compress(data: buffer): buffer
	return data
end

function NoCompression:Decompress(data: buffer): buffer
	return data
end

return {
	RLE = RLECompression,
	LZ77 = LZ77Compression,
	Adaptive = AdaptiveCompression,
	None = NoCompression,
}
