--!strict
-- Ligaya Framework - Configuration
-- Central configuration for debugging and performance tuning

local Config = {
	-- Framework version
	Version = "2.0.0",
	VersionName = "Advanced Type System",

	-- Debug logging flags
	Debug = {
		-- Enable all debug logging
		Enabled = false,

		-- Specific debug categories
		Events = false, -- Log event registration and firing
		Serialization = false, -- Log serialization/deserialization details
		BufferOperations = false, -- Log buffer read/write operations
		NetworkTraffic = false, -- Log bytes sent/received
		Performance = false, -- Log performance metrics
	},

	-- Performance settings
	Performance = {
		MaxBatchSize = 900, -- Maximum bytes per batch
		BufferPoolSize = 32, -- Initial buffer pool size
		DefaultBufferSize = 1024, -- Default buffer size in bytes
	},
}

-- Helper function to check if debug logging is enabled for a category
function Config.IsDebugEnabled(category: string?): boolean
	if not Config.Debug.Enabled then
		return false
	end

	if not category then
		return true
	end

	return Config.Debug[category] == true
end

return Config
