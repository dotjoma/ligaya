#!/usr/bin/env lune
--!strict
-- Run all Ligaya tests

local process = require("@lune/process")
local TestRunner = require("./TestRunner")

-- Import all test suites
require("./BufferPool.test")
require("./FastSerializer.test")
require("./Compression.test")
require("./PriorityQueue.test")
require("./Middleware.test")

-- Run all tests
local success = TestRunner.RunAll()

-- Exit with appropriate code
if success then
	print("✅ All tests passed!")
	process.exit(0)
else
	print("❌ Some tests failed!")
	process.exit(1)
end
