# Ligaya v2.0 Installation Guide

Complete guide for installing and setting up Ligaya v2.0 with advanced type system in your Roblox game.

## Method 1: Manual Installation (Recommended for Development)

### Step 1: Download the Framework

1. Download or clone the Ligaya repository
2. Locate the `Ligaya` folder containing all source files

### Step 2: Import to Roblox Studio

#### Option A: Using Rojo (Recommended)

1. Install Rojo: https://rojo.space/
2. Create a `default.project.json` in your project root:

```json
{
  "name": "YourGame",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "Ligaya": {
        "$path": "Ligaya/src"
      }
    }
  }
}
```

3. Run Rojo:
```bash
rojo serve
```

4. Connect from Roblox Studio (Plugins → Rojo → Connect)

#### Option B: Manual File Import

1. Open Roblox Studio
2. Open your game/place
3. In Explorer, navigate to `ReplicatedStorage`
4. Create a new `ModuleScript` named "Ligaya"
5. Copy the contents of `Ligaya/src/init.luau` into it
6. Create a folder named "Ligaya" in ReplicatedStorage
7. For each file in `Ligaya/src/`:
   - Create a `ModuleScript` with the same name
   - Copy the file contents
   - Place it in the Ligaya folder

**File Structure in Studio:**
```
ReplicatedStorage
└── Ligaya (ModuleScript)
    ├── Types (ModuleScript)
    ├── Client (ModuleScript)
    ├── Server (ModuleScript)
    ├── BufferPool (ModuleScript)
    ├── Middleware (ModuleScript)
    ├── PriorityQueue (ModuleScript)
    ├── Compression (ModuleScript)
    ├── Metrics (ModuleScript)
    └── Retry (ModuleScript)
```

### Step 3: Verify Installation

Create a test script in `ServerScriptService`:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ligaya = require(ReplicatedStorage.Ligaya)

print("Ligaya Version:", Ligaya.VERSION)
print("Installation successful!")
```

Run the game. You should see:
```
Ligaya Version: 2.0.0
Installation successful!
```

---

## Method 2: Roblox Model (Coming Soon)

### Step 1: Get from Roblox Library

1. Open Roblox Studio
2. Go to Toolbox → Models
3. Search for "Ligaya Network Framework"
4. Click to insert into your game

### Step 2: Place in ReplicatedStorage

1. Find the Ligaya model in Workspace
2. Drag it to ReplicatedStorage
3. Verify the structure matches the manual installation

---

## Method 3: Wally Package Manager

### Step 1: Install Wally

```bash
# Install Wally
cargo install wally-cli
```

### Step 2: Add to wally.toml

```toml
[dependencies]
Ligaya = "dotjoma/ligaya@2.0.0"
```

### Step 3: Install

```bash
wally install
```

---

## Initial Setup

### Server Setup

Create a script in `ServerScriptService`:

```lua
--!strict
-- Server/NetworkSetup.server.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ligaya = require(ReplicatedStorage.Ligaya)

-- Initialize Ligaya
Ligaya:Initialize()

-- Register your events
Ligaya:RegisterEvent({
    Name = "PlayerDamage",
    From = "Server",
    Type = "Reliable",
    Call = "ManyAsync",
    Priority = "High",
})

Ligaya:RegisterEvent({
    Name = "ChatMessage",
    From = "Client",
    Type = "Reliable",
    Call = "ManyAsync",
    Priority = "Normal",
})

-- Add middleware (optional)
Ligaya:UseMiddleware(Ligaya.Middleware.RateLimit(10, 1))
Ligaya:UseMiddleware(Ligaya.Middleware.Logging(true))

print("[Ligaya] Server initialized")
```

### Client Setup

Create a script in `StarterPlayer.StarterPlayerScripts`:

```lua
--!strict
-- Client/NetworkSetup.client.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ligaya = require(ReplicatedStorage.Ligaya)

-- Initialize Ligaya
Ligaya:Initialize()

-- Register events (must match server)
Ligaya:RegisterEvent({
    Name = "PlayerDamage",
    From = "Server",
    Type = "Reliable",
    Call = "ManyAsync",
    Priority = "High",
})

Ligaya:RegisterEvent({
    Name = "ChatMessage",
    From = "Client",
    Type = "Reliable",
    Call = "ManyAsync",
    Priority = "Normal",
})

print("[Ligaya] Client initialized")
```

---

## Project Structure

Your final project structure should look like:

```
YourGame
├── ReplicatedStorage
│   └── Ligaya (ModuleScript)
│       ├── Types
│       ├── Client
│       ├── Server
│       ├── BufferPool
│       ├── Middleware
│       ├── PriorityQueue
│       ├── Compression
│       ├── Metrics
│       └── Retry
│
├── ServerScriptService
│   └── NetworkSetup (Script)
│
└── StarterPlayer
    └── StarterPlayerScripts
        └── NetworkSetup (LocalScript)
```

---

## Optional: Install Examples

If you want to include the examples:

1. Create a folder `Examples` in ReplicatedStorage
2. Copy example files:
   - `BasicExample.luau`
   - `AdvancedExample.luau`

To run an example:

```lua
local Examples = ReplicatedStorage.Ligaya.Examples
require(Examples.BasicExample)
```

---

## Optional: Install Benchmarks

For performance testing:

1. Create a folder `Benchmarks` in ReplicatedStorage.Ligaya
2. Copy benchmark files:
   - `BufferAllocation.bench.luau`
   - `EventProcessing.bench.luau`
   - `Compression.bench.luau`
   - `RunAll.luau`

To run benchmarks:

```lua
local Benchmarks = require(ReplicatedStorage.Ligaya.Benchmarks.RunAll)
Benchmarks.RunAll()
```

---

## Troubleshooting

### Error: "Module not found"

**Solution:** Verify the Ligaya folder is in ReplicatedStorage and all module files are present.

### Error: "attempt to index nil"

**Solution:** Make sure you called `Ligaya:Initialize()` before using any features.

### Error: "Client module can only be required from the client"

**Solution:** This is expected. The framework automatically loads the correct module (Client/Server) based on context.

### Events not firing

**Solution:** 
1. Verify event registration matches on both client and server
2. Check that you called `Initialize()` on both sides
3. Ensure event names are exactly the same (case-sensitive)

### Performance issues

**Solution:**
1. Check metrics: `Ligaya:GetMetrics()`
2. Verify buffer pool is working: Check pool hit rate
3. Consider enabling compression for large payloads
4. Review middleware overhead

---

## Updating Ligaya

### Manual Update

1. Download the latest version
2. Replace the Ligaya folder in ReplicatedStorage
3. Test your game thoroughly

### Rojo Update

1. Pull latest changes from repository
2. Rojo will automatically sync changes

### Wally Update

```bash
wally update
```

---

## Uninstalling

1. Remove the Ligaya folder from ReplicatedStorage
2. Remove NetworkSetup scripts from ServerScriptService and StarterPlayerScripts
3. Remove any code that requires Ligaya

---

## Next Steps

- Read the [Quick Start Guide](./QuickStart.md)
- Learn about [Advanced Type System](./AdvancedTypeSystem.md) 🆕
- Check out [RemoteFunction Guide](./RemoteFunctions.md) 🆕
- Review the [Quick Reference](./QuickReference.md) 🆕
- See [Advanced Examples](../examples/advanced.ligaya) 🆕

---

## Support

- Documentation: [Full Docs](./README.md)
- Examples: [/examples](../examples/)
- Issues: GitHub Issues
- Community: Roblox DevForum

---

## License

MIT License - See LICENSE file for details
