--!strict
-- Middleware Logic Tests

local TestRunner = require("./TestRunner")

TestRunner.Suite("Middleware Logic", function()
	TestRunner.Test("should execute middleware in order", function()
		local order = {}
		local middleware = {}

		table.insert(middleware, function(context, next)
			table.insert(order, 1)
			next()
		end)

		table.insert(middleware, function(context, next)
			table.insert(order, 2)
			next()
		end)

		-- Execute pipeline
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

		execute({})

		TestRunner.AssertEqual(#order, 2)
		TestRunner.AssertEqual(order[1], 1)
		TestRunner.AssertEqual(order[2], 2)
	end)

	TestRunner.Test("should support cancellation", function()
		local executed = false
		local middleware = {}

		table.insert(middleware, function(context, next)
			context.cancelled = true
		end)

		table.insert(middleware, function(context, next)
			executed = true
			next()
		end)

		-- Execute with cancellation check
		local function execute(context)
			local index = 1
			local function next()
				if context.cancelled then
					return
				end
				if index <= #middleware then
					local current = index
					index += 1
					middleware[current](context, next)
				end
			end
			next()
		end

		execute({ cancelled = false })

		TestRunner.AssertEqual(executed, false)
	end)

	TestRunner.Test("should allow middleware to modify context", function()
		local middleware = {}

		table.insert(middleware, function(context, next)
			context.value = (context.value or 0) + 1
			next()
		end)

		table.insert(middleware, function(context, next)
			context.value = (context.value or 0) * 2
			next()
		end)

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

		local context = { value = 0 }
		execute(context)

		TestRunner.AssertEqual(context.value, 2) -- (0 + 1) * 2
	end)
end)

TestRunner.Benchmark("Middleware execution", 10000, function()
	local middleware = {
		function(ctx, next)
			next()
		end,
		function(ctx, next)
			next()
		end,
		function(ctx, next)
			next()
		end,
	}

	local index = 1
	local function next()
		if index <= #middleware then
			local current = index
			index += 1
			middleware[current]({}, next)
		end
	end
	next()
end)
