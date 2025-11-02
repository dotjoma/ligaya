--!strict
-- Ligaya Framework - RemoteFunction Support
-- Type-safe request-response pattern with Coroutine/Future/Promise support

local RunService = game:GetService("RunService")

local RemoteFunctionModule = {}

type YieldType = "Coroutine" | "Future" | "Promise"

-- Server-side RemoteFunction manager
local ServerFunctions = {}
local ServerCallbacks: { [string]: (Player, ...any) -> ...any } = {}

-- Client-side RemoteFunction manager
local ClientFunctions = {}

-- Create or get RemoteFunction
local function getOrCreateRemote(name: string): RemoteFunction
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local remoteName = `LIGAYA_FUNC_{name}`

	local existing = ReplicatedStorage:FindFirstChild(remoteName)
	if existing and existing:IsA("RemoteFunction") then
		return existing :: RemoteFunction
	end

	local remote = Instance.new("RemoteFunction")
	remote.Name = remoteName
	remote.Parent = ReplicatedStorage
	return remote
end

-- ============================================
-- SERVER-SIDE API
-- ============================================

function RemoteFunctionModule.RegisterServerFunction(name: string)
	if not RunService:IsServer() then
		error("[Ligaya] RegisterServerFunction can only be called on server")
	end

	if ServerFunctions[name] then
		warn(`[Ligaya] Function '{name}' already registered`)
		return
	end

	local remote = getOrCreateRemote(name)
	ServerFunctions[name] = remote

	-- Set up callback handler
	remote.OnServerInvoke = function(player: Player, ...)
		local callback = ServerCallbacks[name]
		if not callback then
			warn(`[Ligaya] No callback registered for function '{name}'`)
			return nil
		end

		-- Call the callback with player and arguments
		local success, result = pcall(callback, player, ...)
		if not success then
			warn(`[Ligaya] Error in function '{name}': {result}`)
			return nil
		end

		return result
	end
end

function RemoteFunctionModule.OnInvoke(name: string, callback: (Player, ...any) -> ...any)
	if not RunService:IsServer() then
		error("[Ligaya] OnInvoke can only be called on server")
	end

	ServerCallbacks[name] = callback

	-- Return disconnect function
	return function()
		ServerCallbacks[name] = nil
	end
end

-- ============================================
-- CLIENT-SIDE API
-- ============================================

function RemoteFunctionModule.RegisterClientFunction(name: string, yieldType: YieldType)
	if not RunService:IsClient() then
		error("[Ligaya] RegisterClientFunction can only be called on client")
	end

	if ClientFunctions[name] then
		warn(`[Ligaya] Function '{name}' already registered`)
		return
	end

	local remote = getOrCreateRemote(name)
	ClientFunctions[name] = {
		Remote = remote,
		YieldType = yieldType,
	}
end

function RemoteFunctionModule.InvokeServer(name: string, ...: any): ...any
	if not RunService:IsClient() then
		error("[Ligaya] InvokeServer can only be called on client")
	end

	local funcData = ClientFunctions[name]
	if not funcData then
		error(`[Ligaya] Function '{name}' not registered`)
	end

	local remote = funcData.Remote
	local yieldType = funcData.YieldType

	if yieldType == "Coroutine" then
		-- Standard coroutine-based invoke
		return remote:InvokeServer(...)
	elseif yieldType == "Future" then
		-- Future-based (non-blocking)
		-- Note: Requires Future library to be provided
		error("[Ligaya] Future support not yet implemented - use Coroutine for now")
	elseif yieldType == "Promise" then
		-- Promise-based (non-blocking)
		-- Note: Requires Promise library to be provided
		error("[Ligaya] Promise support not yet implemented - use Coroutine for now")
	else
		error(`[Ligaya] Unknown yield type: {yieldType}`)
	end
end

return RemoteFunctionModule
