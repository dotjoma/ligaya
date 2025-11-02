--!strict
-- Ligaya Testing Framework
-- Comprehensive test runner for all framework components

local TestRunner = {}

type TestResult = {
	Name: string,
	Passed: boolean,
	Duration: number,
	Error: string?,
}

type TestSuite = {
	Name: string,
	Tests: { () -> () },
	Results: { TestResult },
}

local suites: { TestSuite } = {}
local currentSuite: TestSuite? = nil

-- Colors for output
local COLORS = {
	Reset = "\27[0m",
	Red = "\27[31m",
	Green = "\27[32m",
	Yellow = "\27[33m",
	Blue = "\27[34m",
	Cyan = "\27[36m",
}

-- Create a new test suite
function TestRunner.Suite(name: string, callback: () -> ())
	local suite: TestSuite = {
		Name = name,
		Tests = {},
		Results = {},
	}

	currentSuite = suite
	table.insert(suites, suite)

	callback()

	currentSuite = nil
end

-- Add a test to current suite
function TestRunner.Test(name: string, callback: () -> ())
	if not currentSuite then
		error("Test must be inside a Suite")
	end

	-- Capture the suite reference before it becomes nil
	local suite = currentSuite

	table.insert(suite.Tests, function()
		local startTime = os.clock()
		local success, err = pcall(callback)
		local duration = os.clock() - startTime

		table.insert(suite.Results, {
			Name = name,
			Passed = success,
			Duration = duration,
			Error = if not success then tostring(err) else nil,
		})
	end)
end

-- Assertion functions
function TestRunner.Assert(condition: boolean, message: string?)
	if not condition then
		error(message or "Assertion failed")
	end
end

function TestRunner.AssertEqual(actual: any, expected: any, message: string?)
	if actual ~= expected then
		error(message or `Expected {expected}, got {actual}`)
	end
end

function TestRunner.AssertNotEqual(actual: any, expected: any, message: string?)
	if actual == expected then
		error(message or `Expected not {expected}, but got {actual}`)
	end
end

function TestRunner.AssertType(value: any, expectedType: string, message: string?)
	local actualType = typeof(value)
	if actualType ~= expectedType then
		error(message or `Expected type {expectedType}, got {actualType}`)
	end
end

function TestRunner.AssertNil(value: any, message: string?)
	if value ~= nil then
		error(message or `Expected nil, got {value}`)
	end
end

function TestRunner.AssertNotNil(value: any, message: string?)
	if value == nil then
		error(message or "Expected non-nil value")
	end
end

function TestRunner.AssertThrows(callback: () -> (), message: string?)
	local success = pcall(callback)
	if success then
		error(message or "Expected function to throw, but it didn't")
	end
end

-- Run all tests
function TestRunner.RunAll(): boolean
	print(
		`\n{COLORS.Cyan}╔════════════════════════════════════════════════════════════╗{COLORS.Reset}`
	)
	print(`{COLORS.Cyan}║         Ligaya Test Runner                                 ║{COLORS.Reset}`)
	print(
		`{COLORS.Cyan}╚════════════════════════════════════════════════════════════╝{COLORS.Reset}\n`
	)

	local totalTests = 0
	local totalPassed = 0
	local totalFailed = 0
	local totalDuration = 0

	for _, suite in suites do
		print(`{COLORS.Blue}▶ {suite.Name}{COLORS.Reset}`)

		-- Run all tests in suite
		for _, test in suite.Tests do
			test()
		end

		-- Print results
		for _, result in suite.Results do
			totalTests += 1
			totalDuration += result.Duration

			if result.Passed then
				totalPassed += 1
				local durationMs = string.format("%.2f", result.Duration * 1000)
				print(`  {COLORS.Green}✓{COLORS.Reset} {result.Name} {COLORS.Yellow}({durationMs}ms){COLORS.Reset}`)
			else
				totalFailed += 1
				print(`  {COLORS.Red}✗{COLORS.Reset} {result.Name}`)
				if result.Error then
					print(`    {COLORS.Red}Error: {result.Error}{COLORS.Reset}`)
				end
			end
		end

		print("")
	end

	-- Summary
	print(
		`{COLORS.Cyan}═══════════════════════════════════════════════════════════{COLORS.Reset}`
	)
	print(`{COLORS.Cyan}Summary:{COLORS.Reset}`)
	print(`  Total: {totalTests}`)
	print(`  {COLORS.Green}Passed: {totalPassed}{COLORS.Reset}`)
	if totalFailed > 0 then
		print(`  {COLORS.Red}Failed: {totalFailed}{COLORS.Reset}`)
	end
	local totalDurationMs = string.format("%.2f", totalDuration * 1000)
	print(`  Duration: {totalDurationMs}ms`)
	print(
		`{COLORS.Cyan}═══════════════════════════════════════════════════════════{COLORS.Reset}\n`
	)

	return totalFailed == 0
end

-- Benchmark function
function TestRunner.Benchmark(name: string, iterations: number, callback: () -> ()): number
	-- Warmup
	for _ = 1, 10 do
		callback()
	end

	-- Actual benchmark
	local startTime = os.clock()
	for _ = 1, iterations do
		callback()
	end
	local duration = os.clock() - startTime
	local avgTime = duration / iterations

	local totalMs = string.format("%.2f", duration * 1000)
	local avgUs = string.format("%.2f", avgTime * 1000000)
	local opsPerSec = string.format("%.0f", 1 / avgTime)

	print(`{COLORS.Yellow}⚡ Benchmark: {name}{COLORS.Reset}`)
	print(`  Iterations: {iterations}`)
	print(`  Total: {totalMs}ms`)
	print(`  Average: {avgUs}µs`)
	print(`  Ops/sec: {opsPerSec}`)
	print("")

	return avgTime
end

return TestRunner
