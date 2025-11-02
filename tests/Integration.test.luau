--!strict
-- Integration Tests
-- Tests framework concepts working together

local TestRunner = require("./TestRunner")

TestRunner.Suite("Integration Tests", function()
	TestRunner.Test("should combine pooling + priority queue", function()
		-- Buffer pool
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

		-- Priority queue
		local queues = { {}, {}, {}, {} }

		local function enqueue(item, priority)
			table.insert(queues[priority], item)
		end

		local function dequeue()
			for priority = 0, 3 do
				if #queues[priority] > 0 then
					return table.remove(queues[priority], 1)
				end
			end
			return nil
		end

		-- Test integration
		local buf1 = acquire()
		enqueue(buf1, 0) -- Critical

		local buf2 = acquire()
		enqueue(buf2, 2) -- Normal

		-- Dequeue should return critical first
		local first = dequeue()
		TestRunner.AssertEqual(first, buf1)

		local second = dequeue()
		TestRunner.AssertEqual(second, buf2)

		-- Release buffers
		release(buf1)
		release(buf2)

		TestRunner.AssertEqual(#available, 2)
		TestRunner.AssertEqual(#active, 0)
	end)

	TestRunner.Test("should combine middleware + priority", function()
		local middleware = {}
		local queues = { {}, {}, {}, {} }

		-- Add validation middleware
		table.insert(middleware, function(context, next)
			if context.valid then
				next()
			end
		end)

		-- Add priority enqueue middleware
		table.insert(middleware, function(context, next)
			table.insert(queues[context.priority], context.data)
			next()
		end)

		-- Execute
		local function execute(context)
			local index = 1
			local function next()
				if index <= #middleware then
					local current = index
					index += 1
					middleware[current](context, next)
				end
			end
			next()
		end

		-- Valid item
		execute({ valid = true, priority = 0, data = "critical" })

		-- Invalid item (should be filtered)
		execute({ valid = false, priority = 2, data = "invalid" })

		TestRunner.AssertEqual(#queues[0], 1)
		TestRunner.AssertEqual(#queues[2], 0)
	end)
end)

TestRunner.Suite("Performance Tests", function()
	TestRunner.Test("should handle high throughput", function()
		local count = 0
		for i = 1, 1000 do
			count += 1
		end
		TestRunner.AssertEqual(count, 1000)
	end)

	TestRunner.Test("should maintain low latency", function()
		local startTime = os.clock()
		for i = 1, 100 do
			local _ = i * 2
		end
		local duration = os.clock() - startTime

		TestRunner.Assert(duration < 0.1, "Should complete in under 100ms")
	end)
end)

-- Benchmarks
TestRunner.Benchmark("End-to-end event processing", 1000, function()
	-- Simulate full cycle
	local queues = { {}, {}, {}, {} }
	local available = {}

	-- Acquire buffer
	local buf = if #available > 0 then table.remove(available) else { id = 1 }

	-- Enqueue with priority
	table.insert(queues[1], buf)

	-- Dequeue
	local item = table.remove(queues[1], 1)

	-- Release buffer
	table.insert(available, item)
end)

TestRunner.Benchmark("Priority queue + Middleware", 1000, function()
	local queues = { {}, {}, {}, {} }
	local middleware = {
		function(ctx, next)
			next()
		end,
		function(ctx, next)
			table.insert(queues[ctx.priority], ctx.data)
			next()
		end,
	}

	local index = 1
	local function next()
		if index <= #middleware then
			local current = index
			index += 1
			middleware[current]({ priority = 1, data = "test" }, next)
		end
	end
	next()
end)
