--!strict
--!native
--!optimize 2
-- Ligaya Framework - Client Network Module
-- High-performance client-side networking with advanced features

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(script.Parent.Config)
local Types = require(script.Parent.Types)
local BufferPool = require(script.Parent.BufferPool)
local MiddlewareModule = require(script.Parent.Middleware)
local PriorityQueue = require(script.Parent.PriorityQueue)
local Compression = require(script.Parent.Compression)
local Metrics = require(script.Parent.Metrics)
local Retry = require(script.Parent.Retry)
local Serializer = require(script.Parent.Serializer)
local FastSerializer = require(script.Parent.FastSerializer)

type EventConfig = Types.EventConfig
type Priority = Types.Priority

local FRAMEWORK_NAME = "LIGAYA"
local PROTOCOL_VERSION = 1

-- Core state
local Client = {
	_initialized = false,
	_events = {},
	_handlers = {},
	_bufferPool = nil,
	_middleware = nil,
	_priorityQueue = nil,
	_compression = nil,
	_metrics = nil,
	_retry = nil,
}

-- Network state
local SendCursor = 0
local SendBuffer = nil
local SendInstances = {}

local RecieveCursor = 0
local RecieveBuffer = nil
local RecieveInstances = {}

-- Remote references
local ReliableRemote: RemoteEvent = nil
local UnreliableRemote: UnreliableRemoteEvent = nil

function Client:Initialize(config: any?)
	if self._initialized then
		warn("[Ligaya] Client already initialized")
		return
	end

	if not RunService:IsClient() then
		error("[Ligaya] Client module can only be used on the client")
	end

	-- Initialize subsystems
	self._bufferPool = BufferPool.new(32, 2048)
	self._middleware = MiddlewareModule.Pipeline.new()
	self._priorityQueue = PriorityQueue.new()
	self._compression = Compression.RLE.new()
	self._metrics = Metrics.new()
	self._retry = Retry.new()

	-- Wait for remotes
	ReliableRemote = ReplicatedStorage:WaitForChild(FRAMEWORK_NAME .. "_RELIABLE") :: RemoteEvent
	UnreliableRemote = ReplicatedStorage:WaitForChild(FRAMEWORK_NAME .. "_UNRELIABLE") :: UnreliableRemoteEvent

	-- Setup listeners
	self:_setupListeners()

	-- Setup replication
	RunService.Heartbeat:Connect(function()
		self:_stepReplication()
	end)

	self._initialized = true
	print(`[Ligaya] Client initialized - v{Config.Version} ({Config.VersionName})`)

	-- Debug: Print registered events after a short delay to ensure all are registered
	task.delay(0.5, function()
		local sortedNames = self:_getSortedEventNames()
		print(`[Ligaya] Client has {#sortedNames} events registered:`)
		for index, name in ipairs(sortedNames) do
			print(`  [{index - 1}] {name}`)
		end
	end)
end

function Client:RegisterEvent(config: EventConfig)
	if self._events[config.Name] then
		warn(`[Ligaya] Event {config.Name} already registered`)
		return
	end

	self._events[config.Name] = config
	self._handlers[config.Name] = {}
	self:_invalidateEventCache() -- Invalidate cache when new event is registered
end

function Client:Fire(eventName: string, ...: any)
	local config = self._events[eventName]
	if not config then
		error(`[Ligaya] Unknown event: {eventName}`)
	end

	if config.From ~= "Client" then
		error(`[Ligaya] Cannot fire server event from client: {eventName}`)
	end

	local data = { ... }
	local priority = config.Priority or "Normal"
	local eventType = config.Type or "Reliable"

	-- Queue event for batched sending
	self._priorityQueue:Enqueue({
		EventName = eventName,
		Data = data,
		Config = config,
		EventType = eventType,
	}, priority)

	self._metrics:RecordEventSent(eventName, 0) -- Size calculated during serialization
end

function Client:On(eventName: string, handler: (...any) -> ())
	local config = self._events[eventName]
	if not config then
		error(`[Ligaya] Unknown event: {eventName}`)
	end

	if config.From ~= "Server" then
		error(`[Ligaya] Cannot listen to client event on client: {eventName}`)
	end

	table.insert(self._handlers[eventName], handler)

	return function()
		local handlers = self._handlers[eventName]
		local index = table.find(handlers, handler)
		if index then
			table.remove(handlers, index)
		end
	end
end

function Client:UseMiddleware(middleware: any)
	self._middleware:Use(middleware)
end

function Client:GetMetrics()
	return self._metrics:GetGlobalMetrics()
end

function Client:GetEventMetrics(eventName: string)
	return self._metrics:GetEventMetrics(eventName)
end

function Client:_setupListeners()
	ReliableRemote.OnClientEvent:Connect(function(buffer: buffer, instances: { Instance })
		self:_processIncoming(buffer, instances, true)
	end)

	UnreliableRemote.OnClientEvent:Connect(function(buffer: buffer, instances: { Instance })
		self:_processIncoming(buffer, instances, false)
	end)
end

function Client:_processIncoming(incomingBuffer: buffer, instances: { Instance }, reliable: boolean)
	RecieveCursor = 0
	RecieveBuffer = incomingBuffer
	RecieveInstances = instances

	local size = buffer.len(RecieveBuffer)

	if Config.IsDebugEnabled("NetworkTraffic") then
		print(`[Ligaya] Client received {size} bytes`)
		if size >= 4 then
			local b0 = buffer.readu8(RecieveBuffer, 0)
			local b1 = buffer.readu8(RecieveBuffer, 1)
			local b2 = buffer.readu8(RecieveBuffer, 2)
			local b3 = buffer.readu8(RecieveBuffer, 3)
			print(`[Ligaya] First 4 bytes: [{b0}, {b1}, {b2}, {b3}]`)
		end
	end

	local eventCount = 0
	while RecieveCursor < size do
		eventCount += 1

		if Config.IsDebugEnabled("Events") then
			print(`[Ligaya] Reading event #{eventCount} at cursor {RecieveCursor}/{size}`)
		end

		-- Read event using FastSerializer
		local eventIndex, data, newCursor = FastSerializer.ReadEvent(RecieveBuffer, RecieveCursor, instances)
		local bytesRead = newCursor - RecieveCursor

		if Config.IsDebugEnabled("Events") then
			print(`[Ligaya] Event #{eventCount}: index={eventIndex}, bytesRead={bytesRead}, newCursor={newCursor}`)
		end

		RecieveCursor = newCursor

		-- Dispatch event
		self:_dispatchEvent(eventIndex, data)

		-- Record metrics
		local eventName = self:_getEventName(eventIndex) or "Unknown"
		self._metrics:RecordEventReceived(eventName, bytesRead)
	end

	if Config.IsDebugEnabled("Events") then
		print(`[Ligaya] Finished processing {eventCount} events`)
	end
end

function Client:_dispatchEvent(eventIndex: number, data: any)
	local eventName = self:_getEventName(eventIndex)

	if not eventName then
		warn(`[Ligaya] Unknown event index: {eventIndex}`)
		return
	end

	local handlers = self._handlers[eventName]
	if not handlers then
		return
	end

	-- Call all registered handlers
	for _, handler in handlers do
		task.spawn(handler, table.unpack(data))
	end
end

function Client:_stepReplication()
	-- Separate buffers for reliable and unreliable events
	local reliableBuffer = self._bufferPool:Acquire(1024)
	local unreliableBuffer = self._bufferPool:Acquire(1024)
	local reliableCursor = 0
	local unreliableCursor = 0
	local reliableInstances = {}
	local unreliableInstances = {}

	local reliableSize = 0
	local unreliableSize = 0
	local maxBatchSize = 900

	-- Process queue and separate by event type
	while self._priorityQueue:Size() > 0 do
		local item = self._priorityQueue:Dequeue()
		if not item then
			break
		end

		local eventType = item.EventType or "Reliable"

		if eventType == "Reliable" then
			if reliableSize >= maxBatchSize then
				break
			end
			SendBuffer = reliableBuffer
			SendCursor = reliableCursor
			SendInstances = reliableInstances

			local eventSize = self:_serializeEvent(item)
			reliableCursor = SendCursor
			reliableSize += eventSize
		else
			if unreliableSize >= maxBatchSize then
				continue
			end
			SendBuffer = unreliableBuffer
			SendCursor = unreliableCursor
			SendInstances = unreliableInstances

			local eventSize = self:_serializeEvent(item)
			unreliableCursor = SendCursor
			unreliableSize += eventSize
		end
	end

	-- Send reliable events
	if reliableCursor > 0 then
		local finalBuffer = buffer.create(reliableCursor)
		buffer.copy(finalBuffer, 0, reliableBuffer, 0, reliableCursor)
		ReliableRemote:FireServer(finalBuffer, reliableInstances)
	end

	-- Send unreliable events
	if unreliableCursor > 0 then
		local finalBuffer = buffer.create(unreliableCursor)
		buffer.copy(finalBuffer, 0, unreliableBuffer, 0, unreliableCursor)
		UnreliableRemote:FireServer(finalBuffer, unreliableInstances)
	end

	-- Return buffers to pool
	self._bufferPool:Release(reliableBuffer)
	self._bufferPool:Release(unreliableBuffer)
	SendBuffer = nil
end

function Client:_serializeEvent(item: any): number
	local eventName = item.EventName
	local eventIndex = self:_getEventIndex(eventName)

	if not eventIndex then
		warn(`[Ligaya] Unknown event: {eventName}`)
		return 0
	end

	-- Write event to buffer using FastSerializer
	local startCursor = SendCursor
	SendCursor = FastSerializer.WriteEvent(SendBuffer, SendCursor, eventIndex, item.Data, SendInstances)

	return SendCursor - startCursor
end

-- Cache sorted event names to ensure consistency
local _sortedEventNamesCache = nil

function Client:_getSortedEventNames(): { string }
	if not _sortedEventNamesCache then
		_sortedEventNamesCache = {}
		for name, _ in pairs(self._events) do
			table.insert(_sortedEventNamesCache, name)
		end
		table.sort(_sortedEventNamesCache)
	end
	return _sortedEventNamesCache
end

function Client:_invalidateEventCache()
	_sortedEventNamesCache = nil
end

function Client:_getEventIndex(eventName: string): number?
	local sortedNames = self:_getSortedEventNames()

	for index, name in ipairs(sortedNames) do
		if name == eventName then
			return index - 1 -- 0-based indexing
		end
	end
	return nil
end

function Client:_getEventName(eventIndex: number): string?
	local sortedNames = self:_getSortedEventNames()
	return sortedNames[eventIndex + 1] -- Convert from 0-based to 1-based
end

-- ============================================
-- REMOTEFUNCTION SUPPORT
-- ============================================

local RemoteFunctionModule = require(script.Parent.RemoteFunction)

function Client:InvokeServer(functionName: string, ...: any): ...any
	if not self._initialized then
		error("[Ligaya] Client not initialized. Call Initialize() first")
	end

	-- Register the function if not already registered (default to Coroutine)
	if not RemoteFunctionModule.ClientFunctions or not RemoteFunctionModule.ClientFunctions[functionName] then
		RemoteFunctionModule.RegisterClientFunction(functionName, "Coroutine")
	end

	-- Invoke the server
	return RemoteFunctionModule.InvokeServer(functionName, ...)
end

return Client
