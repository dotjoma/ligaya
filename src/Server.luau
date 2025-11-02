--!strict
--!native
--!optimize 2
-- Ligaya Framework - Server Network Module
-- High-performance server-side networking with advanced features

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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
local Server = {
	_initialized = false,
	_events = {},
	_handlers = {},
	_bufferPool = nil,
	_middleware = nil,
	_metrics = nil,
	_retry = nil,
}

-- Per-player state
local PlayerQueues = {}
local PlayerBuffers = {}

-- Remote references
local ReliableRemote: RemoteEvent = nil
local UnreliableRemote: UnreliableRemoteEvent = nil

function Server:Initialize(config: any?)
	if self._initialized then
		warn("[Ligaya] Server already initialized")
		return
	end

	if not RunService:IsServer() then
		error("[Ligaya] Server module can only be used on the server")
	end

	-- Initialize subsystems
	self._bufferPool = BufferPool.new(64, 2048)
	self._middleware = MiddlewareModule.Pipeline.new()
	self._metrics = Metrics.new()
	self._retry = Retry.new()

	-- Create remotes
	ReliableRemote = Instance.new("RemoteEvent")
	ReliableRemote.Name = FRAMEWORK_NAME .. "_RELIABLE"
	ReliableRemote.Parent = ReplicatedStorage

	UnreliableRemote = Instance.new("UnreliableRemoteEvent")
	UnreliableRemote.Name = FRAMEWORK_NAME .. "_UNRELIABLE"
	UnreliableRemote.Parent = ReplicatedStorage

	-- Setup listeners
	self:_setupListeners()

	-- Setup player management
	Players.PlayerAdded:Connect(function(player)
		self:_initializePlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_cleanupPlayer(player)
	end)

	-- Setup replication
	RunService.Heartbeat:Connect(function()
		self:_stepReplication()
	end)

	self._initialized = true
	print("[Ligaya] Server initialized")
end

function Server:RegisterEvent(config: EventConfig)
	if self._events[config.Name] then
		warn(`[Ligaya] Event {config.Name} already registered`)
		return
	end

	self._events[config.Name] = config
	self._handlers[config.Name] = {}
end

function Server:Fire(player: Player, eventName: string, ...: any)
	self:_fireToPlayers({ player }, eventName, ...)
end

function Server:FireAll(eventName: string, ...: any)
	self:_fireToPlayers(Players:GetPlayers(), eventName, ...)
end

function Server:FireList(players: { Player }, eventName: string, ...: any)
	self:_fireToPlayers(players, eventName, ...)
end

function Server:FireExcept(excludePlayer: Player, eventName: string, ...: any)
	local players = {}
	for _, player in Players:GetPlayers() do
		if player ~= excludePlayer then
			table.insert(players, player)
		end
	end
	self:_fireToPlayers(players, eventName, ...)
end

function Server:On(eventName: string, handler: (player: Player, ...any) -> ())
	local config = self._events[eventName]
	if not config then
		error(`[Ligaya] Unknown event: {eventName}`)
	end

	if config.From ~= "Client" then
		error(`[Ligaya] Cannot listen to server event on server: {eventName}`)
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

function Server:UseMiddleware(middleware: any)
	self._middleware:Use(middleware)
end

function Server:GetMetrics()
	return self._metrics:GetGlobalMetrics()
end

function Server:GetEventMetrics(eventName: string)
	return self._metrics:GetEventMetrics(eventName)
end

function Server:_initializePlayer(player: Player)
	PlayerQueues[player] = PriorityQueue.new()
	PlayerBuffers[player] = {
		Buffer = self._bufferPool:Acquire(2048),
		Cursor = 0,
		Instances = {},
	}
end

function Server:_cleanupPlayer(player: Player)
	if PlayerBuffers[player] then
		self._bufferPool:Release(PlayerBuffers[player].Buffer)
	end
	PlayerQueues[player] = nil
	PlayerBuffers[player] = nil
end

function Server:_fireToPlayers(players: { Player }, eventName: string, ...: any)
	local config = self._events[eventName]
	if not config then
		error(`[Ligaya] Unknown event: {eventName}`)
	end

	if config.From ~= "Server" then
		error(`[Ligaya] Cannot fire client event from server: {eventName}`)
	end

	local data = { ... }
	local priority = config.Priority or "Normal"
	local eventType = config.Type or "Reliable"

	for _, player in players do
		local queue = PlayerQueues[player]
		if queue then
			queue:Enqueue({
				EventName = eventName,
				Data = data,
				Config = config,
				EventType = eventType,
			}, priority)
		end
	end

	self._metrics:RecordEventSent(eventName, 0)
end

function Server:_setupListeners()
	ReliableRemote.OnServerEvent:Connect(function(player: Player, buffer: buffer, instances: { Instance })
		self:_processIncoming(player, buffer, instances, true)
	end)

	UnreliableRemote.OnServerEvent:Connect(function(player: Player, buffer: buffer, instances: { Instance })
		self:_processIncoming(player, buffer, instances, false)
	end)
end

function Server:_processIncoming(player: Player, incomingBuffer: buffer, instances: { Instance }, reliable: boolean)
	local cursor = 0
	local size = buffer.len(incomingBuffer)

	while cursor < size do
		-- Read event using FastSerializer
		local eventIndex, data, newCursor = FastSerializer.ReadEvent(incomingBuffer, cursor, instances)
		local bytesRead = newCursor - cursor
		cursor = newCursor

		-- Dispatch event
		self:_dispatchEvent(player, eventIndex, data)

		-- Record metrics
		local eventName = self:_getEventName(eventIndex) or "Unknown"
		self._metrics:RecordEventReceived(eventName, bytesRead)
	end
end

function Server:_dispatchEvent(player: Player, eventIndex: number, data: any)
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
		task.spawn(handler, player, table.unpack(data))
	end
end

function Server:_stepReplication()
	for player, queue in PlayerQueues do
		local playerBuffer = PlayerBuffers[player]
		if not playerBuffer then
			continue
		end

		-- Separate buffers for reliable and unreliable
		local reliableBuffer = self._bufferPool:Acquire(2048)
		local unreliableBuffer = self._bufferPool:Acquire(2048)
		local reliableCursor = 0
		local unreliableCursor = 0
		local reliableInstances = {}
		local unreliableInstances = {}

		local reliableSize = 0
		local unreliableSize = 0
		local maxBatchSize = 900

		-- Process queue and separate by event type
		while queue:Size() > 0 do
			local item = queue:Dequeue()
			if not item then
				break
			end

			local eventType = item.EventType or "Reliable"

			if eventType == "Reliable" then
				if reliableSize >= maxBatchSize then
					break
				end
				playerBuffer.Buffer = reliableBuffer
				playerBuffer.Cursor = reliableCursor
				playerBuffer.Instances = reliableInstances

				local eventSize = self:_serializeEvent(item, playerBuffer)
				reliableCursor = playerBuffer.Cursor
				reliableSize += eventSize
			else
				if unreliableSize >= maxBatchSize then
					continue
				end
				playerBuffer.Buffer = unreliableBuffer
				playerBuffer.Cursor = unreliableCursor
				playerBuffer.Instances = unreliableInstances

				local eventSize = self:_serializeEvent(item, playerBuffer)
				unreliableCursor = playerBuffer.Cursor
				unreliableSize += eventSize
			end
		end

		-- Send reliable events
		if reliableCursor > 0 then
			local finalBuffer = buffer.create(reliableCursor)
			buffer.copy(finalBuffer, 0, reliableBuffer, 0, reliableCursor)
			ReliableRemote:FireClient(player, finalBuffer, reliableInstances)
		end

		-- Send unreliable events
		if unreliableCursor > 0 then
			local finalBuffer = buffer.create(unreliableCursor)
			buffer.copy(finalBuffer, 0, unreliableBuffer, 0, unreliableCursor)
			UnreliableRemote:FireClient(player, finalBuffer, unreliableInstances)
		end

		-- Return buffers to pool
		self._bufferPool:Release(reliableBuffer)
		self._bufferPool:Release(unreliableBuffer)
	end
end

function Server:_serializeEvent(item: any, playerBuffer: any): number
	local eventName = item.EventName
	local eventIndex = self:_getEventIndex(eventName)

	if not eventIndex then
		warn(`[Ligaya] Unknown event: {eventName}`)
		return 0
	end

	-- Write event to buffer using FastSerializer
	local startCursor = playerBuffer.Cursor
	playerBuffer.Cursor = FastSerializer.WriteEvent(
		playerBuffer.Buffer,
		playerBuffer.Cursor,
		eventIndex,
		item.Data,
		playerBuffer.Instances
	)

	return playerBuffer.Cursor - startCursor
end

function Server:_getEventIndex(eventName: string): number?
	local index = 0
	for name, _ in pairs(self._events) do
		if name == eventName then
			return index
		end
		index += 1
	end
	return nil
end

function Server:_getEventName(eventIndex: number): string?
	local index = 0
	for name, _ in pairs(self._events) do
		if index == eventIndex then
			return name
		end
		index += 1
	end
	return nil
end

return Server
