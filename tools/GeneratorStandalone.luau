--!strict
-- Ligaya Code Generator - Standalone Version
-- Can be run directly in Roblox Studio

local LigayaParser = require(script.Parent.LigayaParser)

local Generator = {}

-- Generate code from .ligaya file content
function Generator.Generate(ligayaContent: string, moduleName: string): string
	local events = LigayaParser.Parse(ligayaContent)
	local code = LigayaParser.GenerateCode(events, moduleName)
	return code
end

-- Generate code from .ligaya file and save to ModuleScript
function Generator.GenerateToModule(ligayaContent: string, moduleName: string, parent: Instance): ModuleScript
	local code = Generator.Generate(ligayaContent, moduleName)

	local module = Instance.new("ModuleScript")
	module.Name = moduleName
	module.Source = code
	module.Parent = parent

	return module
end

-- Example usage in Studio
function Generator.Example()
	local exampleLigaya = [[
event PlayerDamage {
    from: Server,
    type: Reliable,
    priority: Critical,
    data: (number, string),
}

event PlayerPosition {
    from: Client,
    type: Unreliable,
    priority: High,
    data: (Vector3),
}
]]

	local code = Generator.Generate(exampleLigaya, "NetworkEvents")
	print(code)
end

return Generator
