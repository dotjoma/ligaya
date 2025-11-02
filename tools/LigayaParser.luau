--!strict
-- Ligaya Definition File Parser
-- Parses .ligaya files and generates type-safe Lua code

local LigayaParser = {}

-- Advanced Type System (Inspired by Blink but more powerful)
local TYPE_MAP = {
	-- Basic types
	number = "number",
	string = "string",
	boolean = "boolean",

	-- Roblox types
	Vector3 = "Vector3",
	Vector2 = "Vector2",
	CFrame = "CFrame",
	Color3 = "Color3",
	Instance = "Instance",
	BrickColor = "BrickColor",
	DateTime = "DateTime",
	UDim2 = "UDim2",
	Rect = "Rect",
	Region3 = "Region3",

	-- Integer types (unsigned)
	u8 = "number", -- 0-255
	u16 = "number", -- 0-65535
	u32 = "number", -- 0-4294967295

	-- Integer types (signed)
	i8 = "number", -- -128 to 127
	i16 = "number", -- -32768 to 32767
	i32 = "number", -- -2147483648 to 2147483647

	-- Floating point
	f16 = "number",
	f32 = "number",
	f64 = "number",

	-- Buffer type
	buffer = "buffer",

	-- Empty data
	["()"] = "nil",
}

-- Type metadata for validation and optimization
local TYPE_METADATA = {
	u8 = { min = 0, max = 255, bytes = 1 },
	u16 = { min = 0, max = 65535, bytes = 2 },
	u32 = { min = 0, max = 4294967295, bytes = 4 },
	i8 = { min = -128, max = 127, bytes = 1 },
	i16 = { min = -32768, max = 32767, bytes = 2 },
	i32 = { min = -2147483648, max = 2147483647, bytes = 4 },
	f16 = { bytes = 2 },
	f32 = { bytes = 4 },
	f64 = { bytes = 8 },
}

-- Parse a single line
local function parseLine(line: string): string?
	-- Remove comments
	local withoutComment = line:match("^(.-)%-%-")
	line = withoutComment or line
	local trimmed = line:match("^%s*(.-)%s*$")
	line = trimmed or line

	if line == "" then
		return nil
	end

	return line
end

-- Parse type with advanced features (ranges, optionals, generics, arrays)
local function parseType(typeStr: string): any
	typeStr = typeStr:match("^%s*(.-)%s*$") or typeStr -- Trim

	local typeInfo = {
		BaseType = "",
		IsOptional = false,
		IsArray = false,
		ArrayMin = nil,
		ArrayMax = nil,
		RangeMin = nil,
		RangeMax = nil,
		Generics = {},
		Encoding = nil,
	}

	-- Check for optional (?)
	if typeStr:match("%?$") then
		typeInfo.IsOptional = true
		typeStr = typeStr:sub(1, -2)
		typeStr = typeStr:match("^%s*(.-)%s*$") or typeStr
	end

	-- Check for array ([])
	local arrayMatch = typeStr:match("^(.+)%[(.*)%]$")
	if arrayMatch then
		typeInfo.IsArray = true
		typeStr = arrayMatch
		local rangeStr = typeStr:match("%[(.*)%]$")
		if rangeStr and rangeStr ~= "" then
			-- Parse array range [min..max]
			local min, max = rangeStr:match("^(%d*)%.%.(%d*)$")
			if min and max then
				typeInfo.ArrayMin = tonumber(min) or nil
				typeInfo.ArrayMax = tonumber(max) or nil
			elseif rangeStr:match("^%d+$") then
				-- Exact size [5]
				local size = tonumber(rangeStr)
				typeInfo.ArrayMin = size
				typeInfo.ArrayMax = size
			end
		end
		typeStr = typeStr:match("^(.+)%[") or typeStr
		typeStr = typeStr:match("^%s*(.-)%s*$") or typeStr
	end

	-- Check for encoding <type>
	local encodingMatch = typeStr:match("^(.+)<(.+)>$")
	if encodingMatch then
		local baseType, encoding = typeStr:match("^(.+)<(.+)>$")
		if baseType and encoding then
			typeStr = baseType
			typeInfo.Encoding = encoding:match("^%s*(.-)%s*$") or encoding
		end
	end

	-- Check for range (min..max)
	local rangeMatch = typeStr:match("^(.+)%((.+)%)$")
	if rangeMatch then
		local baseType, range = typeStr:match("^(.+)%((.+)%)$")
		if baseType and range then
			typeStr = baseType
			typeStr = typeStr:match("^%s*(.-)%s*$") or typeStr

			-- Parse range
			local min, max = range:match("^(%d*)%.%.(%d*)$")
			if min and max then
				typeInfo.RangeMin = tonumber(min) or nil
				typeInfo.RangeMax = tonumber(max) or nil
			elseif range:match("^%d+$") then
				-- Exact value
				local val = tonumber(range)
				typeInfo.RangeMin = val
				typeInfo.RangeMax = val
			end
		end
	end

	-- Check for generics Map<K, V>
	local genericMatch = typeStr:match("^(%w+)<(.+)>$")
	if genericMatch then
		local baseType, genericsStr = typeStr:match("^(%w+)<(.+)>$")
		if baseType and genericsStr then
			typeStr = baseType
			-- Parse comma-separated generics
			for generic in genericsStr:gmatch("[^,]+") do
				local trimmedGeneric = generic:match("^%s*(.-)%s*$") or generic
				table.insert(typeInfo.Generics, parseType(trimmedGeneric))
			end
		end
	end

	typeInfo.BaseType = typeStr
	return typeInfo
end

-- Parse event definition
local function parseEvent(lines: { string }, startIndex: number): (any?, number)
	local event = {
		Name = "",
		From = "Server",
		Type = "Reliable",
		Call = "ManyAsync",
		Priority = "Normal",
		Compress = false,
		DataTypes = {},
		ParsedTypes = {}, -- Advanced type info
	}

	-- Parse event name
	local eventLine = lines[startIndex]
	local eventName = eventLine:match("event%s+(%w+)%s*{")
	if not eventName then
		error(`
[Ligaya Parser Error]
Line {startIndex}: Invalid event definition
Expected: event EventName \{ ... \}
Got: {eventLine}
Hint: Check for missing braces or typos in event name
`)
	end

	event.Name = eventName

	-- Parse event properties
	local i = startIndex + 1
	while i <= #lines do
		local line = parseLine(lines[i])

		if not line then
			i += 1
			continue
		end

		-- End of event
		if line:match("^}") then
			return event, i
		end

		-- Parse property
		local key, value = line:match("(%w+):%s*(.+),?")
		if key and value then
			value = value:gsub(",$", "") -- Remove trailing comma

			if key == "from" then
				event.From = value
			elseif key == "type" then
				event.Type = value
			elseif key == "call" then
				event.Call = value
			elseif key == "priority" then
				event.Priority = value
			elseif key == "compress" then
				event.Compress = value == "true"
			elseif key == "data" then
				-- Parse data types with advanced features
				local dataStr = value:match("%((.*)%)")
				if dataStr and dataStr ~= "" then
					for dataType in dataStr:gmatch("[^,]+") do
						local trimmedType = dataType:match("^%s*(.-)%s*$")
						if trimmedType then
							table.insert(event.DataTypes, trimmedType)
							table.insert(event.ParsedTypes, parseType(trimmedType))
						end
					end
				end
			end
		end

		i += 1
	end

	error(`
[Ligaya Parser Error]
Unclosed event definition: {eventName}
Started at line {startIndex}
Hint: Add closing brace \}
`)
end

-- Parse function definition (RemoteFunction equivalent)
local function parseFunction(lines: { string }, startIndex: number): (any?, number)
	local func = {
		Name = "",
		Yield = "Coroutine",
		DataTypes = {},
		ParsedTypes = {},
		ReturnTypes = {},
		ParsedReturnTypes = {},
	}

	-- Parse function name
	local funcLine = lines[startIndex]
	local funcName = funcLine:match("function%s+(%w+)%s*{")
	if not funcName then
		error(`
[Ligaya Parser Error]
Line {startIndex}: Invalid function definition
Expected: function FunctionName \{ ... \}
Got: {funcLine}
Hint: Check for missing braces or typos in function name
`)
	end

	func.Name = funcName

	-- Parse function properties
	local i = startIndex + 1
	while i <= #lines do
		local line = parseLine(lines[i])

		if not line then
			i += 1
			continue
		end

		-- End of function
		if line:match("^}") then
			return func, i
		end

		-- Parse property
		local key, value = line:match("(%w+):%s*(.+),?")
		if key and value then
			value = value:gsub(",$", "") -- Remove trailing comma

			if key == "yield" then
				func.Yield = value
			elseif key == "data" then
				-- Parse data types
				local dataStr = value:match("%((.*)%)")
				if dataStr and dataStr ~= "" then
					for dataType in dataStr:gmatch("[^,]+") do
						local trimmedType = dataType:match("^%s*(.-)%s*$")
						if trimmedType then
							table.insert(func.DataTypes, trimmedType)
							table.insert(func.ParsedTypes, parseType(trimmedType))
						end
					end
				end
			elseif key == "return" then
				-- Parse return types
				local returnStr = value:match("%((.*)%)")
				if returnStr and returnStr ~= "" then
					for returnType in returnStr:gmatch("[^,]+") do
						local trimmedType = returnType:match("^%s*(.-)%s*$")
						if trimmedType then
							table.insert(func.ReturnTypes, trimmedType)
							table.insert(func.ParsedReturnTypes, parseType(trimmedType))
						end
					end
				end
			end
		end

		i += 1
	end

	error(`
[Ligaya Parser Error]
Unclosed function definition: {funcName}
Started at line {startIndex}
Hint: Add closing brace \}
`)
end

-- Parse enum definition
local function parseEnum(lines: { string }, startIndex: number): (any?, number)
	local enum = {
		Name = "",
		IsTagged = false,
		TagField = "Type",
		Variants = {},
	}

	-- Parse enum name and tag field
	local enumLine = lines[startIndex]
	local enumName, tagField = enumLine:match('enum%s+(%w+)%s*=%s*"([^"]+)"%s*{')
	if enumName and tagField then
		enum.Name = enumName
		enum.IsTagged = true
		enum.TagField = tagField
	else
		enumName = enumLine:match("enum%s+(%w+)%s*=%s*{")
		if enumName then
			enum.Name = enumName
			enum.IsTagged = false
		else
			error(`
[Ligaya Parser Error]
Line {startIndex}: Invalid enum definition
Expected: enum EnumName = \{ ... \} or enum EnumName = "TagField" \{ ... \}
Got: {enumLine}
`)
		end
	end

	-- Parse enum variants
	local i = startIndex + 1
	while i <= #lines do
		local line = parseLine(lines[i])

		if not line then
			i += 1
			continue
		end

		-- End of enum
		if line:match("^}") then
			return enum, i
		end

		if enum.IsTagged then
			-- Tagged enum: VariantName { field: type, ... }
			local variantName = line:match("(%w+)%s*{")
			if variantName then
				local variant = {
					Name = variantName,
					Fields = {},
				}
				
				-- Parse variant fields
				i += 1
				while i <= #lines do
					local fieldLine = parseLine(lines[i])
					if not fieldLine then
						i += 1
						continue
					end
					
					if fieldLine:match("^}") then
						break
					end
					
					local fieldName, fieldType = fieldLine:match("(%w+):%s*(.+),?")
					if fieldName and fieldType then
						fieldType = fieldType:gsub(",$", "")
						variant.Fields[fieldName] = parseType(fieldType)
					end
					
					i += 1
				end
				
				table.insert(enum.Variants, variant)
			end
		else
			-- Unit enum: just variant names
			local variantName = line:match("(%w+),?")
			if variantName then
				table.insert(enum.Variants, { Name = variantName })
			end
		end

		i += 1
	end

	error(`
[Ligaya Parser Error]
Unclosed enum definition: {enum.Name}
Started at line {startIndex}
Hint: Add closing brace \}
`)
end

-- Parse .ligaya file
function LigayaParser.Parse(content: string): { any }
	local lines = {}
	for line in content:gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end

	local definitions = {
		Events = {},
		Functions = {},
		Enums = {},
		Options = {},
	}
	local i = 1

	while i <= #lines do
		local line = parseLine(lines[i])

		if line then
			if line:match("^event%s+") then
				local event, endIndex = parseEvent(lines, i)
				table.insert(definitions.Events, event)
				i = endIndex
			elseif line:match("^function%s+") then
				local func, endIndex = parseFunction(lines, i)
				table.insert(definitions.Functions, func)
				i = endIndex
			elseif line:match("^enum%s+") then
				local enum, endIndex = parseEnum(lines, i)
				table.insert(definitions.Enums, enum)
				i = endIndex
			elseif line:match("^option%s+") then
				-- Parse options
				local optionName, optionValue = line:match("option%s+(%w+)%s*=%s*(.+)")
				if optionName and optionValue then
					optionValue = optionValue:gsub('"', ""):gsub("'", "")
					definitions.Options[optionName] = optionValue
				end
			end
		end

		i += 1
	end

	return definitions
end

-- Convert parsed type to Luau type string
local function typeToLuauString(typeInfo: any): string
	local baseType = TYPE_MAP[typeInfo.BaseType] or "any"
	
	-- Handle arrays
	if typeInfo.IsArray then
		baseType = `\{{baseType}\}`
	end
	
	-- Handle optionals
	if typeInfo.IsOptional then
		baseType = `{baseType}?`
	end
	
	return baseType
end

-- Generate Luau type string from parsed types
local function generateTypeString(parsedTypes: { any }): string
	if #parsedTypes == 0 then
		return ""
	end

	local types = {}
	for _, typeInfo in parsedTypes do
		table.insert(types, typeToLuauString(typeInfo))
	end

	return table.concat(types, ", ")
end

-- Generate parameter list with types
local function generateParamList(parsedTypes: { any }): string
	if #parsedTypes == 0 then
		return ""
	end

	local params = {}
	for i, typeInfo in parsedTypes do
		table.insert(params, `param{i}: {typeToLuauString(typeInfo)}`)
	end

	return table.concat(params, ", ")
end

-- Generate validation code for runtime type checking
local function generateValidation(paramName: string, typeInfo: any): string
	local checks = {}
	
	-- Type check
	local expectedType = TYPE_MAP[typeInfo.BaseType] or "any"
	if expectedType ~= "any" then
		table.insert(checks, `assert(typeof({paramName}) == "{expectedType}", "Expected {expectedType}, got " .. typeof({paramName}))`)
	end
	
	-- Range check for numbers
	if typeInfo.RangeMin or typeInfo.RangeMax then
		if typeInfo.RangeMin and typeInfo.RangeMax then
			table.insert(checks, `assert({paramName} >= {typeInfo.RangeMin} and {paramName} <= {typeInfo.RangeMax}, "Value out of range [{typeInfo.RangeMin}..{typeInfo.RangeMax}]")`)
		elseif typeInfo.RangeMin then
			table.insert(checks, `assert({paramName} >= {typeInfo.RangeMin}, "Value must be >= {typeInfo.RangeMin}")`)
		elseif typeInfo.RangeMax then
			table.insert(checks, `assert({paramName} <= {typeInfo.RangeMax}, "Value must be <= {typeInfo.RangeMax}")`)
		end
	end
	
	-- Array length check
	if typeInfo.IsArray and (typeInfo.ArrayMin or typeInfo.ArrayMax) then
		if typeInfo.ArrayMin and typeInfo.ArrayMax then
			table.insert(checks, `assert(#{paramName} >= {typeInfo.ArrayMin} and #{paramName} <= {typeInfo.ArrayMax}, "Array length out of range [{typeInfo.ArrayMin}..{typeInfo.ArrayMax}]")`)
		elseif typeInfo.ArrayMin then
			table.insert(checks, `assert(#{paramName} >= {typeInfo.ArrayMin}, "Array length must be >= {typeInfo.ArrayMin}")`)
		elseif typeInfo.ArrayMax then
			table.insert(checks, `assert(#{paramName} <= {typeInfo.ArrayMax}, "Array length must be <= {typeInfo.ArrayMax}")`)
		end
	end
	
	return table.concat(checks, "\n\t")
end

-- Generate type-safe Lua code
function LigayaParser.GenerateCode(definitions: any, moduleName: string): string
	local code = {
		"--!strict",
		"-- Auto-generated by Ligaya Code Generator v2.0",
		"-- DO NOT EDIT THIS FILE MANUALLY",
		"-- Generated with advanced type system, enums, and functions",
		"",
		'local ReplicatedStorage = game:GetService("ReplicatedStorage")',
		"local Ligaya = require(ReplicatedStorage.Ligaya)",
		"",
		`local {moduleName} = \{\}`,
		"",
	}
	
	-- Apply options
	local writeValidations = definitions.Options.WriteValidations == "true"
	
	-- Generate enum types
	if #definitions.Enums > 0 then
		table.insert(code, "-- Enum Types")
		for _, enum in definitions.Enums do
			if enum.IsTagged then
				-- Tagged enum type
				table.insert(code, `export type {enum.Name} =`)
				for i, variant in enum.Variants do
					local fields = {}
					table.insert(fields, `{enum.TagField}: "{variant.Name}"`)
					for fieldName, fieldType in pairs(variant.Fields) do
						table.insert(fields, `{fieldName}: {typeToLuauString(fieldType)}`)
					end
					local separator = i < #enum.Variants and " |" or ""
					table.insert(code, `\t| \{{ {table.concat(fields, ", ")} \}}{separator}`)
				end
			else
				-- Unit enum type
				local variants = {}
				for _, variant in enum.Variants do
					table.insert(variants, `"{variant.Name}"`)
				end
				table.insert(code, `export type {enum.Name} = {table.concat(variants, " | ")}`)
			end
		end
		table.insert(code, "")
	end
	
	-- Initialize Ligaya
	table.insert(code, "-- Initialize Ligaya")
	table.insert(code, "Ligaya:Initialize()")
	table.insert(code, "")
	
	-- Register all events
	if #definitions.Events > 0 then
		table.insert(code, "-- Register events")
		for _, event in definitions.Events do
			table.insert(code, `Ligaya:RegisterEvent(\{`)
			table.insert(code, `\tName = "{event.Name}",`)
			table.insert(code, `\tFrom = "{event.From}",`)
			table.insert(code, `\tType = "{event.Type}",`)
			table.insert(code, `\tCall = "{event.Call}",`)
			table.insert(code, `\tPriority = "{event.Priority}",`)
			if event.Compress then
				table.insert(code, `\tCompress = true,`)
			end
			table.insert(code, `\})`)
			table.insert(code, "")
		end
	end

	-- Generate type-safe event wrappers
	if #definitions.Events > 0 then
		table.insert(code, "-- Type-safe event wrappers")
		table.insert(code, "")

		for _, event in definitions.Events do
			local typeStr = generateTypeString(event.ParsedTypes)
			local paramList = generateParamList(event.ParsedTypes)

			-- Generate Fire methods based on direction
			if event.From == "Client" then
				-- Client events
				table.insert(code, `-- {event.Name}: Client -> Server`)
				table.insert(code, `function {moduleName}.{event.Name}Fire({paramList})`)
				
				-- Add validation if enabled
				if writeValidations then
					for i, typeInfo in event.ParsedTypes do
						local validation = generateValidation(`param{i}`, typeInfo)
						if validation ~= "" then
							table.insert(code, `\t{validation}`)
						end
					end
				end
				
				if #event.ParsedTypes > 0 then
					local params = {}
					for i = 1, #event.ParsedTypes do
						table.insert(params, `param{i}`)
					end
					table.insert(code, `\tLigaya:Fire("{event.Name}", {table.concat(params, ", ")})`)
				else
					table.insert(code, `\tLigaya:Fire("{event.Name}")`)
				end
				table.insert(code, "end")
				table.insert(code, "")

				-- Server-side listener
				table.insert(
					code,
					`function {moduleName}.{event.Name}On(handler: (player: Player{#event.ParsedTypes > 0 and ", " or ""}{typeStr}) -> ())`
				)
				table.insert(code, `\treturn Ligaya:On("{event.Name}", handler)`)
				table.insert(code, "end")
				table.insert(code, "")
			else
				-- Server events
				table.insert(code, `-- {event.Name}: Server -> Client`)
				table.insert(
					code,
					`function {moduleName}.{event.Name}Fire(player: Player{#event.ParsedTypes > 0 and ", " or ""}{paramList})`
				)
				
				-- Add validation if enabled
				if writeValidations then
					for i, typeInfo in event.ParsedTypes do
						local validation = generateValidation(`param{i}`, typeInfo)
						if validation ~= "" then
							table.insert(code, `\t{validation}`)
						end
					end
				end
				
				if #event.ParsedTypes > 0 then
					local params = {}
					for i = 1, #event.ParsedTypes do
						table.insert(params, `param{i}`)
					end
					table.insert(code, `\tLigaya:Fire(player, "{event.Name}", {table.concat(params, ", ")})`)
				else
					table.insert(code, `\tLigaya:Fire(player, "{event.Name}")`)
				end
				table.insert(code, "end")
				table.insert(code, "")

				table.insert(code, `function {moduleName}.{event.Name}FireAll({paramList})`)
				if #event.ParsedTypes > 0 then
					local params = {}
					for i = 1, #event.ParsedTypes do
						table.insert(params, `param{i}`)
					end
					table.insert(code, `\tLigaya:FireAll("{event.Name}", {table.concat(params, ", ")})`)
				else
					table.insert(code, `\tLigaya:FireAll("{event.Name}")`)
				end
				table.insert(code, "end")
				table.insert(code, "")

				table.insert(
					code,
					`function {moduleName}.{event.Name}FireList(players: \{Player\}{#event.ParsedTypes > 0 and ", " or ""}{paramList})`
				)
				if #event.ParsedTypes > 0 then
					local params = {}
					for i = 1, #event.ParsedTypes do
						table.insert(params, `param{i}`)
					end
					table.insert(code, `\tLigaya:FireList(players, "{event.Name}", {table.concat(params, ", ")})`)
				else
					table.insert(code, `\tLigaya:FireList(players, "{event.Name}")`)
				end
				table.insert(code, "end")
				table.insert(code, "")

				table.insert(
					code,
					`function {moduleName}.{event.Name}FireExcept(excludePlayer: Player{#event.ParsedTypes > 0 and ", " or ""}{paramList})`
				)
				if #event.ParsedTypes > 0 then
					local params = {}
					for i = 1, #event.ParsedTypes do
						table.insert(params, `param{i}`)
					end
					table.insert(code, `\tLigaya:FireExcept(excludePlayer, "{event.Name}", {table.concat(params, ", ")})`)
				else
					table.insert(code, `\tLigaya:FireExcept(excludePlayer, "{event.Name}")`)
				end
				table.insert(code, "end")
				table.insert(code, "")

				-- Client-side listener
				table.insert(code, `function {moduleName}.{event.Name}On(handler: ({typeStr}) -> ())`)
				table.insert(code, `\treturn Ligaya:On("{event.Name}", handler)`)
				table.insert(code, "end")
				table.insert(code, "")
			end
		end
	end
	
	-- Generate RemoteFunction wrappers
	if #definitions.Functions > 0 then
		table.insert(code, "-- Type-safe function wrappers (RemoteFunction)")
		table.insert(code, "")
		
		for _, func in definitions.Functions do
			local paramTypeStr = generateTypeString(func.ParsedTypes)
			local paramList = generateParamList(func.ParsedTypes)
			local returnTypeStr = generateTypeString(func.ParsedReturnTypes)
			
			-- Client invoke
			table.insert(code, `-- {func.Name}: Client -> Server`)
			table.insert(code, `function {moduleName}.{func.Name}Invoke({paramList}): {returnTypeStr}`)
			
			-- Add validation if enabled
			if writeValidations then
				for i, typeInfo in func.ParsedTypes do
					local validation = generateValidation(`param{i}`, typeInfo)
					if validation ~= "" then
						table.insert(code, `\t{validation}`)
					end
				end
			end
			
			if #func.ParsedTypes > 0 then
				local params = {}
				for i = 1, #func.ParsedTypes do
					table.insert(params, `param{i}`)
				end
				table.insert(code, `\treturn Ligaya:InvokeServer("{func.Name}", {table.concat(params, ", ")})`)
			else
				table.insert(code, `\treturn Ligaya:InvokeServer("{func.Name}")`)
			end
			table.insert(code, "end")
			table.insert(code, "")
			
			-- Server callback
			table.insert(
				code,
				`function {moduleName}.{func.Name}On(handler: (player: Player{#func.ParsedTypes > 0 and ", " or ""}{paramTypeStr}) -> ({returnTypeStr}))`
			)
			table.insert(code, `\treturn Ligaya:OnInvoke("{func.Name}", handler)`)
			table.insert(code, "end")
			table.insert(code, "")
		end
	end

	table.insert(code, `return {moduleName}`)

	return table.concat(code, "\n")
end

return LigayaParser
