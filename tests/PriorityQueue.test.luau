--!strict
-- PriorityQueue Logic Tests

local TestRunner = require("./TestRunner")

TestRunner.Suite("PriorityQueue Logic", function()
	TestRunner.Test("should implement priority ordering", function()
		-- Priority levels: Critical=0, High=1, Normal=2, Low=3
		local function getPriority(level: string): number
			if level == "Critical" then
				return 0
			elseif level == "High" then
				return 1
			elseif level == "Normal" then
				return 2
			elseif level == "Low" then
				return 3
			else
				return 2
			end
		end

		TestRunner.AssertEqual(getPriority("Critical"), 0)
		TestRunner.AssertEqual(getPriority("High"), 1)
		TestRunner.AssertEqual(getPriority("Normal"), 2)
		TestRunner.AssertEqual(getPriority("Low"), 3)
	end)

	TestRunner.Test("should maintain priority order", function()
		local queues = {
			[0] = {}, -- Critical
			[1] = {}, -- High
			[2] = {}, -- Normal
			[3] = {}, -- Low
		}

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

		-- Add items
		enqueue("low", 3)
		enqueue("critical", 0)
		enqueue("normal", 2)
		enqueue("high", 1)

		-- Dequeue should return in priority order
		TestRunner.AssertEqual(dequeue(), "critical")
		TestRunner.AssertEqual(dequeue(), "high")
		TestRunner.AssertEqual(dequeue(), "normal")
		TestRunner.AssertEqual(dequeue(), "low")
	end)

	TestRunner.Test("should handle FIFO within same priority", function()
		local queue = {}

		table.insert(queue, "first")
		table.insert(queue, "second")
		table.insert(queue, "third")

		TestRunner.AssertEqual(table.remove(queue, 1), "first")
		TestRunner.AssertEqual(table.remove(queue, 1), "second")
		TestRunner.AssertEqual(table.remove(queue, 1), "third")
	end)
end)

TestRunner.Benchmark("Priority queue operations", 10000, function()
	local queues = { {}, {}, {}, {} }

	-- Enqueue
	table.insert(queues[2], "item")

	-- Dequeue
	for i = 1, 4 do
		if #queues[i] > 0 then
			table.remove(queues[i], 1)
			break
		end
	end
end)
