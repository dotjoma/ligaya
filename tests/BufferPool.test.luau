--!strict
-- BufferPool Logic Tests
-- Tests the pooling concept without Roblox dependencies

local TestRunner = require("./TestRunner")

TestRunner.Suite("BufferPool Logic", function()
	TestRunner.Test("should implement basic pooling", function()
		local available = {}
		local active = {}

		local function acquire()
			if #available > 0 then
				local buf = table.remove(available)
				table.insert(active, buf)
				return buf
			else
				local buf = { id = #active + #available + 1 }
				table.insert(active, buf)
				return buf
			end
		end

		local function release(buf)
			for i, b in active do
				if b == buf then
					table.remove(active, i)
					table.insert(available, buf)
					return
				end
			end
		end

		-- Test acquire
		local buf1 = acquire()
		TestRunner.AssertNotNil(buf1)
		TestRunner.AssertEqual(#active, 1)

		-- Test release
		release(buf1)
		TestRunner.AssertEqual(#active, 0)
		TestRunner.AssertEqual(#available, 1)

		-- Test reuse
		local buf2 = acquire()
		TestRunner.AssertEqual(buf1, buf2)
	end)

	TestRunner.Test("should track statistics", function()
		local stats = {
			hits = 0,
			misses = 0,
			total = 0,
			active = 0,
		}
		local available = {}
		local active = {}

		local function acquire()
			if #available > 0 then
				stats.hits += 1
				local buf = table.remove(available)
				table.insert(active, buf)
				stats.active += 1
				return buf
			else
				stats.misses += 1
				stats.total += 1
				local buf = { id = stats.total }
				table.insert(active, buf)
				stats.active += 1
				return buf
			end
		end

		local function release(buf)
			for i, b in active do
				if b == buf then
					table.remove(active, i)
					table.insert(available, buf)
					stats.active -= 1
					return
				end
			end
		end

		local buf1 = acquire() -- Miss
		local buf2 = acquire() -- Miss
		release(buf1)
		local buf3 = acquire() -- Hit

		TestRunner.AssertEqual(stats.hits, 1)
		TestRunner.AssertEqual(stats.misses, 2)
		TestRunner.AssertEqual(stats.total, 2)
		TestRunner.AssertEqual(stats.active, 2)
	end)
end)

-- Benchmark pooling concept
TestRunner.Benchmark("Pool acquire/release", 10000, function()
	local available = {}
	local active = {}

	-- Acquire
	local buf
	if #available > 0 then
		buf = table.remove(available)
		table.insert(active, buf)
	else
		buf = { id = 1 }
		table.insert(active, buf)
	end

	-- Release
	for i, b in active do
		if b == buf then
			table.remove(active, i)
			table.insert(available, buf)
			break
		end
	end
end)
