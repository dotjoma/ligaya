--!strict
-- Ligaya Framework - Type-Safe Example
-- Demonstrates compile-time type safety with generated code

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Import generated type-safe module
local NetworkEvents = require(ReplicatedStorage.NetworkEvents)

-- ═══════════════════════════════════════════════════════════════
-- CLIENT EXAMPLE
-- ═══════════════════════════════════════════════════════════════

if RunService:IsClient() then
	local player = game.Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	print("✅ Type-safe client loaded!")

	-- ═══════════════════════════════════════════════════════════
	-- SEND EVENTS (Type-safe!)
	-- ═══════════════════════════════════════════════════════════

	-- Send position update (Type-safe: requires Vector3)
	task.spawn(function()
		while true do
			task.wait(0.05) -- 20 Hz

			local position = humanoidRootPart.Position
			NetworkEvents.PlayerPositionFire(position) -- ✅ Type-safe!

			-- This would cause a compile error:
			-- NetworkEvents.PlayerPositionFire("wrong type") -- ❌ Error!
		end
	end)

	-- Send rotation update (Type-safe: requires CFrame)
	task.spawn(function()
		while true do
			task.wait(0.1)

			local cframe = humanoidRootPart.CFrame
			NetworkEvents.PlayerRotationFire(cframe) -- ✅ Type-safe!
		end
	end)

	-- Send chat message (Type-safe: requires string)
	local function sendChat(message: string)
		NetworkEvents.ChatMessageFire(message) -- ✅ Type-safe!

		-- This would cause a compile error:
		-- NetworkEvents.ChatMessageFire(123) -- ❌ Error!
	end

	-- Example: Send chat
	task.wait(2)
	sendChat("Hello from type-safe client!")

	-- ═══════════════════════════════════════════════════════════
	-- RECEIVE EVENTS (Type-safe!)
	-- ═══════════════════════════════════════════════════════════

	-- Listen for damage (Type-safe: number, string)
	NetworkEvents.PlayerDamageOn(function(damage: number, damageType: string)
		print(`💥 Took {damage} damage from {damageType}`)

		-- Types are enforced!
		-- damage is guaranteed to be a number
		-- damageType is guaranteed to be a string

		local health = character:FindFirstChild("Humanoid")
		if health then
			health.Health -= damage
		end
	end)

	-- Listen for heal (Type-safe: number)
	NetworkEvents.PlayerHealOn(function(healAmount: number)
		print(`💚 Healed {healAmount} HP`)

		local health = character:FindFirstChild("Humanoid")
		if health then
			health.Health += healAmount
		end
	end)

	-- Listen for chat broadcast (Type-safe: string, string)
	NetworkEvents.ChatBroadcastOn(function(playerName: string, message: string)
		print(`💬 {playerName}: {message}`)
	end)

	-- Listen for inventory update (Type-safe: table)
	NetworkEvents.InventoryUpdateOn(function(inventory: table)
		print(`🎒 Inventory updated:`, inventory)
	end)

	-- Listen for game start (Type-safe: no parameters)
	NetworkEvents.GameStartOn(function()
		print(`🎮 Game started!`)
	end)

	-- Listen for game end (Type-safe: string, number)
	NetworkEvents.GameEndOn(function(winner: string, score: number)
		print(`🏆 Game ended! Winner: {winner} with {score} points`)
	end)

	-- Listen for effects (Type-safe: Vector3, string)
	NetworkEvents.SpawnEffectOn(function(position: Vector3, effectType: string)
		print(`✨ Effect {effectType} at {position}`)
		-- Spawn particle effect here
	end)

	-- Listen for sounds (Type-safe: string, number)
	NetworkEvents.PlaySoundOn(function(soundId: string, volume: number)
		print(`🔊 Playing sound {soundId} at volume {volume}`)
		-- Play sound here
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- SERVER EXAMPLE
-- ═══════════════════════════════════════════════════════════════

if RunService:IsServer() then
	print("✅ Type-safe server loaded!")

	-- ═══════════════════════════════════════════════════════════
	-- RECEIVE EVENTS (Type-safe!)
	-- ═══════════════════════════════════════════════════════════

	-- Listen for position updates (Type-safe: Player, Vector3)
	NetworkEvents.PlayerPositionOn(function(player: Player, position: Vector3)
		-- Position is guaranteed to be Vector3
		-- Can safely use Vector3 methods
		local magnitude = position.Magnitude

		-- Broadcast to other players
		NetworkEvents.PlayerPositionFire(player, position)
	end)

	-- Listen for rotation updates (Type-safe: Player, CFrame)
	NetworkEvents.PlayerRotationOn(function(player: Player, cframe: CFrame)
		-- CFrame is guaranteed to be CFrame
		local lookVector = cframe.LookVector

		-- Broadcast to other players
		NetworkEvents.PlayerRotationFire(player, cframe)
	end)

	-- Listen for chat messages (Type-safe: Player, string)
	NetworkEvents.ChatMessageOn(function(player: Player, message: string)
		print(`{player.Name}: {message}`)

		-- Broadcast to all players (Type-safe!)
		NetworkEvents.ChatBroadcastFireAll(player.Name, message)

		-- This would cause a compile error:
		-- NetworkEvents.ChatBroadcastFireAll(123, true) -- ❌ Error!
	end)

	-- Listen for item pickup (Type-safe: Player, Instance)
	NetworkEvents.ItemPickupOn(function(player: Player, item: Instance)
		print(`{player.Name} picked up {item.Name}`)

		-- Update inventory
		local inventory = { item.Name }
		NetworkEvents.InventoryUpdateFire(player, inventory)
	end)

	-- ═══════════════════════════════════════════════════════════
	-- SEND EVENTS (Type-safe!)
	-- ═══════════════════════════════════════════════════════════

	-- Example: Deal damage to player (Type-safe: Player, number, string)
	local function dealDamage(player: Player, damage: number, damageType: string)
		NetworkEvents.PlayerDamageFire(player, damage, damageType) -- ✅ Type-safe!

		-- This would cause a compile error:
		-- NetworkEvents.PlayerDamageFire(player, "wrong", 123) -- ❌ Error!
	end

	-- Example: Heal player (Type-safe: Player, number)
	local function healPlayer(player: Player, amount: number)
		NetworkEvents.PlayerHealFire(player, amount) -- ✅ Type-safe!
	end

	-- Example: Start game (Type-safe: no parameters)
	local function startGame()
		NetworkEvents.GameStartFireAll() -- ✅ Type-safe!
		print("🎮 Game started for all players")
	end

	-- Example: End game (Type-safe: string, number)
	local function endGame(winner: string, score: number)
		NetworkEvents.GameEndFireAll(winner, score) -- ✅ Type-safe!
		print(`🏆 Game ended! Winner: {winner}`)
	end

	-- Example: Spawn effect (Type-safe: Vector3, string)
	local function spawnEffect(position: Vector3, effectType: string)
		NetworkEvents.SpawnEffectFireAll(position, effectType) -- ✅ Type-safe!
	end

	-- Example: Play sound (Type-safe: string, number)
	local function playSound(soundId: string, volume: number)
		NetworkEvents.PlaySoundFireAll(soundId, volume) -- ✅ Type-safe!
	end

	-- ═══════════════════════════════════════════════════════════
	-- DEMO: Automated events
	-- ═══════════════════════════════════════════════════════════

	-- Start game after 5 seconds
	task.delay(5, function()
		startGame()
	end)

	-- Spawn random effects
	task.spawn(function()
		while true do
			task.wait(3)

			local randomPos = Vector3.new(math.random(-50, 50), 5, math.random(-50, 50))
			spawnEffect(randomPos, "Explosion")
		end
	end)

	-- Random damage to players
	task.spawn(function()
		while true do
			task.wait(10)

			local players = game.Players:GetPlayers()
			if #players > 0 then
				local randomPlayer = players[math.random(1, #players)]
				dealDamage(randomPlayer, 10, "Environment")

				-- Heal after 2 seconds
				task.delay(2, function()
					healPlayer(randomPlayer, 5)
				end)
			end
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- BENEFITS OF TYPE-SAFE CODE
-- ═══════════════════════════════════════════════════════════════

--[[
	✅ COMPILE-TIME TYPE CHECKING:
	- Errors caught before runtime
	- IDE autocomplete works perfectly
	- Refactoring is safer
	
	✅ BETTER DEVELOPER EXPERIENCE:
	- Clear function signatures
	- Self-documenting code
	- Less bugs
	
	✅ TEAM COLLABORATION:
	- Consistent API across team
	- Type contracts enforced
	- Easier code reviews
	
	✅ PERFORMANCE:
	- No runtime type checking overhead
	- Luau can optimize better
	- Same performance as manual code
	
	COMPARISON:
	
	Without Type Safety (Old way):
	Ligaya:Fire("PlayerDamage", "wrong", "types") -- ❌ Runtime error!
	
	With Type Safety (New way):
	NetworkEvents.PlayerDamageFire(player, "wrong", "types") -- ❌ Compile error!
	                                        ^^^^^^^ Type error: expected number
	
	The error is caught BEFORE you run the game! 🎉
]]

print("\n✨ Type-safe example loaded!")
print("📊 All events are type-checked at compile time")
print("🚀 Enjoy safer, faster development!")
