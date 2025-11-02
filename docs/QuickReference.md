# Ligaya v2.0 Quick Reference

Fast reference for Ligaya Framework syntax and features.

## Type System

### Integer Types
```lua
u8          -- 0-255 (1 byte)
u16         -- 0-65535 (2 bytes)
u32         -- 0-4294967295 (4 bytes)
i8          -- -128 to 127 (1 byte)
i16         -- -32768 to 32767 (2 bytes)
i32         -- -2147483648 to 2147483647 (4 bytes)
```

### Float Types
```lua
f16         -- Half precision (2 bytes)
f32         -- Single precision (4 bytes)
f64         -- Double precision (8 bytes)
```

### Bounded Types
```lua
u8(0..100)      -- Range 0-100
u8(10..)        -- Minimum 10
u8(..100)       -- Maximum 100
u8(50)          -- Exactly 50
string(3..20)   -- 3-20 characters
```

### Optional Types
```lua
string?         -- Optional string
u8?             -- Optional u8
Vector3?        -- Optional Vector3
```

### Array Types
```lua
number[]        -- Unbounded array
u32[1..50]      -- 1-50 elements
string[5]       -- Exactly 5 elements
```

### Roblox Types
```lua
Vector3         Vector2         CFrame
Color3          Instance        BrickColor
DateTime        UDim2           Rect
Region3         buffer
```

## Events

### Basic Event
```lua
event EventName {
    from: Server,              -- Server or Client
    type: Reliable,            -- Reliable or Unreliable
    call: ManyAsync,           -- SingleSync, ManySync, SingleAsync, ManyAsync
    priority: Normal,          -- Critical, High, Normal, Low
    data: (u8, string)         -- Data types
}
```

### Event with Compression
```lua
event LargeData {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    priority: Low,
    compress: true,            -- Enable compression
    data: (string, buffer)
}
```

## Functions

### Basic Function
```lua
function FunctionName {
    yield: Coroutine,          -- Coroutine, Future, Promise
    data: (u32),               -- Input types
    return: (string, u8)       -- Return types
}
```

## Enums

### Unit Enum
```lua
enum DamageType = {
    Physical,
    Fire,
    Ice
}
```

### Tagged Enum
```lua
enum PlayerAction = "Type" {
    Move {
        Position: Vector3,
        Speed: f32
    },
    Attack {
        Target: u16,
        Damage: u8(1..100)
    }
}
```

## Options

```lua
option WriteValidations = true     -- Enable runtime validation
option Casing = Pascal              -- Pascal, Camel, Snake
```

## Generated API

### Events (Client → Server)
```lua
-- Client
NetworkEvents.EventNameFire(param1, param2)

-- Server
NetworkEvents.EventNameOn(function(player, param1, param2)
    -- Handle event
end)
```

### Events (Server → Client)
```lua
-- Server
NetworkEvents.EventNameFire(player, param1, param2)
NetworkEvents.EventNameFireAll(param1, param2)
NetworkEvents.EventNameFireList(players, param1, param2)
NetworkEvents.EventNameFireExcept(excludePlayer, param1, param2)

-- Client
NetworkEvents.EventNameOn(function(param1, param2)
    -- Handle event
end)
```

### Functions
```lua
-- Client
local result1, result2 = NetworkEvents.FunctionNameInvoke(param1, param2)

-- Server
NetworkEvents.FunctionNameOn(function(player, param1, param2)
    return result1, result2
end)
```

## Framework API

### Initialization
```lua
local Ligaya = require(ReplicatedStorage.Ligaya)
Ligaya:Initialize()
```

### Middleware
```lua
-- Rate limiting
Ligaya:UseMiddleware(Ligaya.Middleware.RateLimit(10, 1))

-- Validation
Ligaya:UseMiddleware(Ligaya.Middleware.Validation(validator))

-- Logging
Ligaya:UseMiddleware(Ligaya.Middleware.Logging())
```

### Metrics
```lua
local metrics = Ligaya:GetMetrics()
print(metrics.EventsSent)
print(metrics.BytesSent)
print(metrics.AverageLatency)
print(metrics.CompressionRatio)
```

## Code Generation

```bash
# Generate code
lune run Packages/Ligaya/tools/generate.luau input.ligaya output.luau

# Example
lune run Packages/Ligaya/tools/generate.luau events.ligaya NetworkEvents.luau
```

## Common Patterns

### Health System
```lua
event PlayerDamage {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    priority: Critical,
    data: (u8(1..100), string)  -- Damage, type
}

event PlayerHeal {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    priority: High,
    data: (u8(1..100))  -- Heal amount
}
```

### Movement System
```lua
event PlayerPosition {
    from: Client,
    type: Unreliable,
    call: ManySync,
    priority: High,
    data: (Vector3, f32)  -- Position, speed
}
```

### Inventory System
```lua
event InventoryUpdate {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    priority: High,
    data: (u32[1..50], u8[1..50])  -- IDs, quantities
}

function PurchaseItem {
    yield: Coroutine,
    data: (u32, u8(1..99)),
    return: (boolean, string?)  -- Success, error
}
```

### Chat System
```lua
event PlayerChat {
    from: Client,
    type: Reliable,
    call: ManyAsync,
    priority: Normal,
    data: (string(1..200), string?)  -- Message, channel
}
```

## Performance Tips

### 1. Use Appropriate Types
```lua
-- ❌ Bad: Wastes bandwidth
data: (number, number, number)  -- 24 bytes

-- ✅ Good: Optimized
data: (u8, u16, u8)             -- 4 bytes
```

### 2. Use Unreliable for High-Frequency
```lua
-- ✅ Good: Position updates
event PlayerPosition {
    from: Client,
    type: Unreliable,  -- Don't need reliability
    call: ManySync,
    priority: High,
    data: (Vector3)
}
```

### 3. Use Priority Levels
```lua
-- Critical: Combat, damage
priority: Critical

-- High: Movement, inventory
priority: High

-- Normal: Chat, UI updates
priority: Normal

-- Low: Background sync, analytics
priority: Low
```

### 4. Enable Compression for Large Data
```lua
event LargeData {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    priority: Low,
    compress: true,  -- Compress large payloads
    data: (string, buffer)
}
```

## Debugging

### Enable Debug Logging
```lua
-- In Config.luau
Debug = {
    Enabled = true,
    Events = true,
    Serialization = true,
    NetworkTraffic = true,
}
```

### Check Metrics
```lua
local metrics = Ligaya:GetMetrics()
print(`Events: {metrics.EventsSent}`)
print(`Bandwidth: {metrics.BytesSent} bytes`)
print(`Latency: {metrics.AverageLatency}ms`)
```

## Error Handling

### Events
```lua
NetworkEvents.EventNameOn(function(...)
    local success, err = pcall(function()
        -- Handle event
    end)
    
    if not success then
        warn(`Error: {err}`)
    end
end)
```

### Functions
```lua
local success, result = pcall(function()
    return NetworkEvents.FunctionNameInvoke(...)
end)

if not success then
    warn(`Error: {result}`)
end
```

## Links

- [Advanced Type System](./AdvancedTypeSystem.md)
- [RemoteFunction Guide](./RemoteFunctions.md)
- [Migration from Blink](./MigrationFromBlink.md)
- [Full Documentation](./API.md)
