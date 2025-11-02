--!strict
-- Ligaya Framework - Advanced Example
-- Demonstrates advanced features: compression, custom middleware, metrics

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Ligaya = require(ReplicatedStorage.Ligaya)

-- Custom middleware for profanity filtering
local function ProfanityFilterMiddleware(bannedWords: {string})
	return function(context, next)
		if context.EventName == "ChatMessage" then
			local message = context.Data[1]
			
			for _, word in bannedWords do
				if string.find(string.lower(message), string.lower(word)) then
					warn(`[Filter] Blocked message from {context.Player.Name}: {message}`)
					context.Cancel()
					return
				end
			end
		end
		
		next()
	end
end

-- Custom middleware for anti-spam
local function AntiSpamMiddleware(maxDuplicates: number)
	local recentMessages = {}
	
	return function(context, next)
		if context.EventName == "ChatMessage" then
			local player = context.Player
			local message = context.Data[1]
			
			if not recentMessages[player] then
				recentMessages[player] = {}
			end
			
			local playerMessages = recentMessages[player]
			
			-- Count duplicates
			local duplicateCount = 0
			for _, msg in playerMessages do
				if msg == message then
					duplicateCount += 1
				end
			end
			
			if duplicateCount >= maxDuplicates then
				warn(`[AntiSpam] Blocked duplicate message from {player.Name}`)
				context.Cancel()
				return
			end
			
			-- Add to recent messages
			table.insert(playerMessages, message)
			if #playerMessages > 10 then
				table.remove(playerMessages, 1)
			end
		end
		
		next()
	end
end

if RunService:IsServer() then
	-- SERVER SIDE - Advanced Setup
	print("[Advanced] Initializing Ligaya Server with advanced features...")
	
	Ligaya:Initialize({
		EnableCompression = true,
		EnableMetrics = true,
		EnableRetry = true,
	})
	
	-- Register events with various priorities
	Ligaya:RegisterEvent({
		Name = "ChatMessage",
		From = "Client",
		Type = "Reliable",
		Call = "ManyAsync",
		Priority = "Normal",
		RateLimit = {
			MaxCalls = 3,
			WindowSeconds = 1,
		},
	})
	
	Ligaya:RegisterEvent({
		Name = "CriticalAlert",
		From = "Server",
		Type = "Reliable",
		Call = "SingleAsync",
		Priority = "Critical",
	})
	
	Ligaya:RegisterEvent({
		Name = "WorldData",
		From = "Server",
		Type = "Reliable",
		Call = "SingleAsync",
		Priority = "Normal",
		Compress = true, -- Enable compression for large data
	})
	
	Ligaya:RegisterEvent({
		Name = "PositionSync",
		From = "Server",
		Type = "Unreliable",
		Call = "ManySync",
		Priority = "Low",
	})
	
	-- Add multiple middleware layers
	Ligaya:UseMiddleware(Ligaya.Middleware.RateLimit(10, 1))
	Ligaya:UseMiddleware(ProfanityFilterMiddleware({"badword", "spam", "hack"}))
	Ligaya:UseMiddleware(AntiSpamMiddleware(3))
	Ligaya:UseMiddleware(Ligaya.Middleware.Logging(true))
	
	-- Validation middleware for chat messages
	Ligaya:UseMiddleware(Ligaya.Middleware.Validation(function(data)
		if type(data[1]) ~= "string" then
			return false
		end
		
		local message = data[1]
		return #message > 0 and #message <= 200
	end))
	
	-- Handle chat messages
	Ligaya:On("ChatMessage", function(player: Player, message: string)
		print(`[Chat] {player.Name}: {message}`)
		Ligaya:FireAll("ChatMessage", player.Name, message)
	end)
	
	-- Simulate critical alerts
	task.spawn(function()
		while true do
			task.wait(30)
			
			Ligaya:FireAll("CriticalAlert", "Server restart in 5 minutes!")
			print("[Server] Sent critical alert")
		end
	end)
	
	-- Simulate large world data transfer
	task.spawn(function()
		task.wait(5)
		
		-- Create large data payload
		local worldData = {}
		for i = 1, 1000 do
			worldData[i] = {
				x = math.random(-1000, 1000),
				y = math.random(-1000, 1000),
				tileId = math.random(1, 100),
			}
		end
		
		local players = game.Players:GetPlayers()
		if #players > 0 then
			Ligaya:Fire(players[1], "WorldData", worldData)
			print("[Server] Sent large world data (will be compressed)")
		end
	end)
	
	-- Advanced metrics reporting
	task.spawn(function()
		while true do
			task.wait(15)
			
			local metrics = Ligaya:GetMetrics()
			print("\n╔════════════════════════════════════╗")
			print("║   Ligaya Advanced Metrics          ║")
			print("╠════════════════════════════════════╣")
			print(`║ Events Sent:       {metrics.EventsSent}`)
			print(`║ Events Received:   {metrics.EventsReceived}`)
			print(`║ Bytes Sent:        {metrics.BytesSent}`)
			print(`║ Bytes Received:    {metrics.BytesReceived}`)
			print(`║ Avg Latency:       {metrics.AverageLatency * 1000:.2f}ms`)
			print(`║ Compression Ratio: {metrics.CompressionRatio * 100:.1f}%`)
			print(`║ Errors:            {metrics.ErrorCount}`)
			print("╚════════════════════════════════════╝\n")
			
			-- Per-event metrics
			local chatMetrics = Ligaya:GetEventMetrics("ChatMessage")
			if chatMetrics then
				print(`Chat Messages: {chatMetrics.CallCount} calls, {chatMetrics.AverageSize:.0f} bytes avg`)
			end
		end
	end)
	
elseif RunService:IsClient() then
	-- CLIENT SIDE - Advanced Setup
	print("[Advanced] Initializing Ligaya Client...")
	
	Ligaya:Initialize()
	
	-- Register events (must match server)
	Ligaya:RegisterEvent({
		Name = "ChatMessage",
		From = "Client",
		Type = "Reliable",
		Call = "ManyAsync",
		Priority = "Normal",
	})
	
	Ligaya:RegisterEvent({
		Name = "CriticalAlert",
		From = "Server",
		Type = "Reliable",
		Call = "SingleAsync",
		Priority = "Critical",
	})
	
	Ligaya:RegisterEvent({
		Name = "WorldData",
		From = "Server",
		Type = "Reliable",
		Call = "SingleAsync",
		Priority = "Normal",
		Compress = true,
	})
	
	-- Handle critical alerts with high priority
	Ligaya:On("CriticalAlert", function(message: string)
		print(`\n⚠️  CRITICAL ALERT: {message} ⚠️\n`)
		-- Show UI notification
	end)
	
	-- Handle large world data
	Ligaya:On("WorldData", function(data: any)
		print(`[Client] Received world data with {#data} tiles (decompressed)`)
		-- Process world data
	end)
	
	-- Handle chat messages
	Ligaya:On("ChatMessage", function(playerName: string, message: string)
		print(`[Chat] {playerName}: {message}`)
	end)
	
	-- Simulate varied message sending
	task.spawn(function()
		task.wait(3)
		
		local messageTypes = {
			{ text = "Normal message", delay = 5 },
			{ text = "Quick message", delay = 1 },
			{ text = "Another message", delay = 3 },
		}
		
		while true do
			for _, msgType in messageTypes do
				task.wait(msgType.delay)
				Ligaya:Fire("ChatMessage", msgType.text)
			end
		end
	end)
end
