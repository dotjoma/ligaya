--!strict
-- Serialization Logic Tests

local TestRunner = require("./TestRunner")

TestRunner.Suite("Serialization Logic", function()
	TestRunner.Test("should serialize basic types", function()
		-- Test type identification
		local function getTypeId(value)
			local t = typeof(value)
			if t == "nil" then
				return 0
			elseif t == "boolean" then
				return 1
			elseif t == "number" then
				return 2
			elseif t == "string" then
				return 3
			elseif t == "table" then
				return 9
			else
				return 255
			end
		end

		TestRunner.AssertEqual(getTypeId(nil), 0)
		TestRunner.AssertEqual(getTypeId(true), 1)
		TestRunner.AssertEqual(getTypeId(42), 2)
		TestRunner.AssertEqual(getTypeId("test"), 3)
		TestRunner.AssertEqual(getTypeId({}), 9)
	end)

	TestRunner.Test("should handle arrays vs tables", function()
		local function isArray(tbl)
			if type(tbl) ~= "table" then
				return false
			end

			local maxIndex = 0
			local count = 0

			for k, _ in pairs(tbl) do
				count += 1
				if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then
					return false
				end
				if k > maxIndex then
					maxIndex = k
				end
			end

			return maxIndex == count
		end

		TestRunner.Assert(isArray({ 1, 2, 3 }))
		TestRunner.Assert(not isArray({ a = 1, b = 2 }))
		TestRunner.Assert(not isArray({ [1] = "a", [3] = "c" })) -- Gap
	end)
end)

TestRunner.Benchmark("Type identification", 10000, function()
	local value = 42
	local t = typeof(value)
	local typeId = if t == "number" then 2 else 0
end)
