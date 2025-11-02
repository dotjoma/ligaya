--!strict
-- Ligaya Framework - Basic Example
-- Demonstrates core functionality

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Ligaya = require(ReplicatedStorage.Ligaya)

if RunService:IsServer() then
	-- SERVER SIDE
	print("[Example] Initializing Ligaya Server...")
	
	Ligaya:Initialize()
	
	-- Register events
	Ligaya:RegisterEvent({
		Name = "ChatMessage",
		From = "Client",
		Type = "Reliable",
		Call = "ManyAsync",
		Priority = "Normal",
	})
	
	Ligaya:RegisterEvent({
		Name = "PlayerDamage",
		From = "Server",
		Type = "Reliable",
		Call = "ManyAsync",
		Priority = "High",
	})
	
	Ligaya:RegisterEvent({
		Name = "PositionUpdate",
		From = "Server",
		Type = "Unreliable",
		Call = "ManySync",
		Priority = "Low",
	})
	
	-- Add middleware
	Ligaya:UseMiddleware(Ligaya.Middleware.RateLimit(5, 1)) -- 5 messages per second
	Ligaya:UseMiddleware(Ligaya.Middleware.Logging(true))
	
	-- Listen to client events
	Ligaya:On("ChatMessage", function(player: Player, message: string)
		print(`[Chat] {player.Name}: {message}`)
		
		-- Broadcast to all players
		Ligaya:FireAll("ChatMessage", player.Name, message)
	end)
	
	-- Simulate damage events
	task.spawn(function()
		while true do
			task.wait(2)
			
			local players = game.Players:GetPlayers()
			if #players > 0 then
				local randomPlayer = players[math.random(1, #players)]
				local damage = math.random(10, 50)
				
				Ligaya:Fire(randomPlayer, "PlayerDamage", damage, "Environment")
				print(`[Server] Sent {damage} damage to {randomPlayer.Name}`)
			end
		end
	end)
	
	-- Print metrics every 10 seconds
	task.spawn(function()
		while true do
			task.wait(10)
			
			local metrics = Ligaya:GetMetrics()
			print("\n=== Ligaya Metrics ===")
			print(`Events Sent: {metrics.EventsSent}`)
			print(`Events Received: {metrics.EventsReceived}`)
			print(`Bytes Sent: {metrics.BytesSent}`)
			print(`Average Latency: {metrics.AverageLatency * 1000:.2f}ms`)
			print("=====================\n")
		end
	end)
	
elseif RunService:IsClient() then
	-- CLIENT SIDE
	print("[Example] Initializing Ligaya Client...")
	
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
		Name = "PlayerDamage",
		From = "Server",
		Type = "Reliable",
		Call = "ManyAsync",
		Priority = "High",
	})
	
	Ligaya:RegisterEvent({
		Name = "PositionUpdate",
		From = "Server",
		Type = "Unreliable",
		Call = "ManySync",
		Priority = "Low",
	})
	
	-- Listen to server events
	Ligaya:On("PlayerDamage", function(damage: number, damageType: string)
		print(`[Client] Took {damage} damage from {damageType}!`)
		
		-- Update UI here
		-- ShowDamageIndicator(damage)
	end)
	
	Ligaya:On("ChatMessage", function(playerName: string, message: string)
		print(`[Chat] {playerName}: {message}`)
		
		-- Update chat UI here
		-- AddChatMessage(playerName, message)
	end)
	
	-- Send a test message every 5 seconds
	task.spawn(function()
		task.wait(2) -- Wait for initialization
		
		while true do
			task.wait(5)
			
			local messages = {
				"Hello everyone!",
				"How's it going?",
				"This is a test message",
				"Ligaya is awesome!",
			}
			
			local randomMessage = messages[math.random(1, #messages)]
			Ligaya:Fire("ChatMessage", randomMessage)
			print(`[Client] Sent message: {randomMessage}`)
		end
	end)
end
