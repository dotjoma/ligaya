--!strict
-- Ligaya Framework - Retry Logic
-- Exponential backoff retry mechanism for failed operations

local Types = require(script.Parent.Types)

type RetryConfig = Types.RetryConfig
type RetryableOperation = Types.RetryableOperation

local DEFAULT_CONFIG: RetryConfig = {
	MaxAttempts = 3,
	InitialDelay = 0.1,
	MaxDelay = 5.0,
	BackoffMultiplier = 2.0,
}

local RetryManager = {}
RetryManager.__index = RetryManager

function RetryManager.new()
	local self = setmetatable({}, RetryManager)
	self._activeRetries = {}
	return self :: any
end

function RetryManager:Execute(operation: RetryableOperation)
	local config = operation.Config or DEFAULT_CONFIG
	local attempt = 0
	local delay = config.InitialDelay

	local function tryExecute()
		attempt += 1

		local success, result = pcall(operation.Execute)

		if success and result then
			-- Operation succeeded
			if operation.OnSuccess then
				operation.OnSuccess()
			end
			return
		end

		-- Operation failed
		if attempt >= config.MaxAttempts then
			-- Max attempts reached
			if operation.OnFailure then
				operation.OnFailure(`Max retry attempts ({config.MaxAttempts}) reached`)
			end
			return
		end

		-- Schedule retry with exponential backoff
		task.delay(delay, tryExecute)

		-- Increase delay for next attempt
		delay = math.min(delay * config.BackoffMultiplier, config.MaxDelay)
	end

	-- Start first attempt
	tryExecute()
end

-- Convenience function for simple retries
function RetryManager:ExecuteWithRetry(
	fn: () -> boolean,
	config: RetryConfig?,
	onSuccess: (() -> ())?,
	onFailure: ((error: string) -> ())?
)
	self:Execute({
		Execute = fn,
		OnSuccess = onSuccess,
		OnFailure = onFailure,
		Config = config or DEFAULT_CONFIG,
	})
end

return RetryManager
