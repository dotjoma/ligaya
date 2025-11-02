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

print(`⚙️  Parsing events...`)

-- Parse .ligaya file
local success, events = pcall(function()
	return LigayaParser.Parse(content)
end)

if not success then
	print(`❌ Parse error: {events}`)
	process.exit(1)
end

print(`✅ Found {#events} events:`)
for _, event in events do
	local dataStr = #event.DataTypes > 0 and `({table.concat(event.DataTypes, ", ")})` or "()"
	print(`   • {event.Name} {dataStr}`)
end

print(`\n🔨 Generating type-safe code...`)

-- Generate module name from output file
local moduleName = outputFile:match("([^/\\]+)%.luau?$") or "NetworkEvents"
moduleName = moduleName:gsub("%.luau?$", "")

-- Generate code
local code = LigayaParser.GenerateCode(events, moduleName)

print(`💾 Writing: {outputFile}`)

-- Write output file
fs.writeFile(outputFile, code)

print(`\n✅ Code generation complete!`)
print(`\n📊 Summary:`)
print(`   Events: {#events}`)
print(`   Output: {outputFile}`)
print(`   Lines: {select(2, code:gsub("\n", "\n")) + 1}`)

print(`\n🎯 Usage:`)
print(`   local {moduleName} = require(path.to.{moduleName})`)
print(`   {moduleName}.PlayerDamageFire(player, 25, "Fire")`)
print(`   {moduleName}.PlayerDamageOn(function(damage, type) end)`)

print(`\n✨ Type-safe networking ready!\n`)
