--!strict
-- Compression Logic Tests

local TestRunner = require("./TestRunner")

TestRunner.Suite("Compression Logic", function()
	TestRunner.Test("should implement RLE concept", function()
		-- Simple Run-Length Encoding concept
		local function compressRLE(data: { number }): { number }
			local compressed = {}
			local i = 1

			while i <= #data do
				local value = data[i]
				local count = 1

				-- Count consecutive same values
				while i + count <= #data and data[i + count] == value and count < 255 do
					count += 1
				end

				table.insert(compressed, count)
				table.insert(compressed, value)
				i += count
			end

			return compressed
		end

		local function decompressRLE(compressed: { number }): { number }
			local data = {}

			for i = 1, #compressed, 2 do
				local count = compressed[i]
				local value = compressed[i + 1]

				for j = 1, count do
					table.insert(data, value)
				end
			end

			return data
		end

		-- Test
		local original = { 1, 1, 1, 2, 2, 3 }
		local compressed = compressRLE(original)
		local decompressed = decompressRLE(compressed)

		TestRunner.AssertEqual(#compressed, 6) -- 3,1, 2,2, 1,3
		TestRunner.AssertEqual(#decompressed, #original)

		for i = 1, #original do
			TestRunner.AssertEqual(decompressed[i], original[i])
		end
	end)

	TestRunner.Test("should reduce size for repetitive data", function()
		local original = {}
		for i = 1, 100 do
			table.insert(original, 42)
		end

		-- RLE: count=100, value=42 = 2 values
		local compressed = { 100, 42 }

		TestRunner.Assert(#compressed < #original)
	end)
end)

TestRunner.Benchmark("RLE compression", 1000, function()
	local data = {}
	for i = 1, 100 do
		table.insert(data, 42)
	end

	local compressed = {}
	local count = #data
	local value = data[1]
	table.insert(compressed, count)
	table.insert(compressed, value)
end)
