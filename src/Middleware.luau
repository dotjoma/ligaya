--!strict
-- Ligaya Framework - Middleware Pipeline
-- Decorator pattern for extensible request processing

local Types = require(script.Parent.Types)

type Middleware = Types.Middleware
type MiddlewareContext = Types.MiddlewareContext
type MiddlewarePipeline = Types.MiddlewarePipeline

local MiddlewarePipeline = {}
MiddlewarePipeline.__index = MiddlewarePipeline

function MiddlewarePipeline.new(): MiddlewarePipeline
	local self = setmetatable({}, MiddlewarePipeline)
	self._middlewares = {}
	return self :: any
end

function MiddlewarePipeline:Use(middleware: Middleware)
	table.insert(self._middlewares, middleware)
end

function MiddlewarePipeline:Execute(context: MiddlewareContext): boolean
	local index = 1
	local cancelled = false

	-- Create cancel function
	context.Cancel = function()
		cancelled = true
	end

	-- Recursive next function
	local function next()
		if cancelled then
			return
		end

		local middleware = self._middlewares[index]
		if not middleware then
			return
		end

		index += 1
		middleware(context, next)
	end

	-- Start pipeline
	next()

	context.IsCancelled = cancelled
	return not cancelled
end

function MiddlewarePipeline:Clear()
	table.clear(self._middlewares)
end

-- Built-in middleware factories

local Middlewares = {}

-- Rate limiting middleware
function Middlewares.RateLimit(maxCalls: number, windowSeconds: number): Middleware
	local callCounts = {}

	return function(context: MiddlewareContext, next: () -> ())
		local player = context.Player
		if not player then
			next()
			return
		end

		local userId = player.UserId
		local now = os.clock()

		-- Initialize or clean old entries
		if not callCounts[userId] then
			callCounts[userId] = { Count = 0, WindowStart = now }
		end

		local record = callCounts[userId]

		-- Reset window if expired
		if now - record.WindowStart >= windowSeconds then
			record.Count = 0
			record.WindowStart = now
		end

		-- Check rate limit
		if record.Count >= maxCalls then
			warn(`[Ligaya] Rate limit exceeded for {player.Name} on {context.EventName}`)
			context.Cancel()
			return
		end

		record.Count += 1
		next()
	end
end

-- Validation middleware
function Middlewares.Validation(validator: (data: any) -> boolean): Middleware
	return function(context: MiddlewareContext, next: () -> ())
		if not validator(context.Data) then
			warn(`[Ligaya] Validation failed for {context.EventName}`)
			context.Cancel()
			return
		end
		next()
	end
end

-- Logging middleware
function Middlewares.Logging(verbose: boolean?): Middleware
	return function(context: MiddlewareContext, next: () -> ())
		local start = os.clock()

		if verbose then
			print(`[Ligaya] {context.EventName} called by {context.Player and context.Player.Name or "Server"}`)
		end

		next()

		if verbose then
			local elapsed = (os.clock() - start) * 1000
			local elapsedStr = string.format("%.2f", elapsed)
			print(`[Ligaya] {context.EventName} completed in {elapsedStr}ms`)
		end
	end
end

-- Metrics middleware
function Middlewares.Metrics(metricsCollector: any): Middleware
	return function(context: MiddlewareContext, next: () -> ())
		local start = os.clock()

		next()

		local elapsed = os.clock() - start
		metricsCollector:Record(context.EventName, elapsed, context.IsCancelled)
	end
end

return {
	Pipeline = MiddlewarePipeline,
	Middlewares = Middlewares,
}
