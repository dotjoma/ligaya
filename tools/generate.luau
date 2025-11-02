--!strict
-- Ligaya Code Generator CLI Tool
-- Usage: lune run generate.luau <input.ligaya> <output.luau>

local fs = require("@lune/fs")
local process = require("@lune/process")
local LigayaParser = require("./LigayaParser")

-- Parse command line arguments
local args = process.args

if #args < 2 then
	print("Usage: lune run generate.luau <input.ligaya> <output.luau>")
	print("Example: lune run generate.luau events.ligaya NetworkEvents.luau")
	process.exit(1)
end

local inputFile = args[1]
local outputFile = args[2]

-- Check if input file exists
if not fs.isFile(inputFile) then
	print(`Error: Input file not found: {inputFile}`)
	process.exit(1)
end

print(
	`\n╔════════════════════════════════════════════════════════════╗`
)
print(`║         Ligaya Code Generator                              ║`)
print(
	`╚════════════════════════════════════════════════════════════╝\n`
)

print(`📄 Reading: {inputFile}`)

-- Read input file
local content = fs.readFile(inputFile)

print(`⚙️  Parsing definitions...`)

-- Parse .ligaya file
local success, definitions = pcall(function()
	return LigayaParser.Parse(content)
end)

if not success then
	print(`❌ Parse error: {definitions}`)
	process.exit(1)
end

print(`✅ Found definitions:`)
print(`   Events: {#definitions.Events}`)
print(`   Functions: {#definitions.Functions}`)
print(`   Enums: {#definitions.Enums}`)

if #definitions.Events > 0 then
	print(`\n📡 Events:`)
	for _, event in definitions.Events do
		local dataStr = #event.DataTypes > 0 and `({table.concat(event.DataTypes, ", ")})` or "()"
		print(`   • {event.Name} {dataStr}`)
	end
end

if #definitions.Functions > 0 then
	print(`\n🔧 Functions:`)
	for _, func in definitions.Functions do
		local dataStr = #func.DataTypes > 0 and `({table.concat(func.DataTypes, ", ")})` or "()"
		local returnStr = #func.ReturnTypes > 0 and ` -> ({table.concat(func.ReturnTypes, ", ")})` or ""
		print(`   • {func.Name} {dataStr}{returnStr}`)
	end
end

if #definitions.Enums > 0 then
	print(`\n📋 Enums:`)
	for _, enum in definitions.Enums do
		local variantCount = #enum.Variants
		local enumType = enum.IsTagged and "Tagged" or "Unit"
		print(`   • {enum.Name} ({enumType}, {variantCount} variants)`)
	end
end

print(`\n🔨 Generating type-safe code...`)

-- Generate module name from output file
local moduleName = outputFile:match("([^/\\]+)%.luau?$") or "NetworkEvents"
moduleName = moduleName:gsub("%.luau?$", "")

-- Generate code
local code = LigayaParser.GenerateCode(definitions, moduleName)

print(`💾 Writing: {outputFile}`)

-- Write output file
fs.writeFile(outputFile, code)

print(`\n✅ Code generation complete!`)
print(`\n📊 Summary:`)
print(`   Events: {#definitions.Events}`)
print(`   Functions: {#definitions.Functions}`)
print(`   Enums: {#definitions.Enums}`)
print(`   Output: {outputFile}`)
print(`   Lines: {select(2, code:gsub("\n", "\n")) + 1}`)

print(`\n🎯 Usage Examples:`)
if #definitions.Events > 0 then
	print(`   -- Events:`)
	print(`   local {moduleName} = require(path.to.{moduleName})`)
	print(`   {moduleName}.{definitions.Events[1].Name}Fire(...)`)
	print(`   {moduleName}.{definitions.Events[1].Name}On(function(...) end)`)
end
if #definitions.Functions > 0 then
	print(`   -- Functions:`)
	print(`   local result = {moduleName}.{definitions.Functions[1].Name}Invoke(...)`)
	print(`   {moduleName}.{definitions.Functions[1].Name}On(function(player, ...) return ... end)`)
end

print(`\n✨ Advanced type-safe networking ready!\n`)
