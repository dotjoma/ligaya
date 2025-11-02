--!strict
-- Ligaya Framework - Main Entry Point
-- A high-performance networking framework for Roblox

local RunService = game:GetService("RunService")

local Config = require(script.Config)

-- Export the appropriate module based on context
local Ligaya

if RunService:IsServer() then
	Ligaya = require(script.Server)
elseif RunService:IsClient() then
	Ligaya = require(script.Client)
else
	-- Studio edit mode - return dummy module
	Ligaya = {
		Initialize = function() end,
		RegisterEvent = function() end,
		VERSION = Config.Version,
		VERSION_NAME = Config.VersionName,
		PROTOCOL_VERSION = 1,
	}
	return Ligaya
end

-- Add middleware utilities
local MiddlewareModule = require(script.Middleware)
Ligaya.Middleware = MiddlewareModule.Middlewares

-- Export compression module
Ligaya.Compression = require(script.Compression)

-- Add version info from Config
Ligaya.VERSION = Config.Version
Ligaya.VERSION_NAME = Config.VersionName
Ligaya.PROTOCOL_VERSION = 1

-- Export Config for external access
Ligaya.Config = Config

return Ligaya
