# Ligaya v2.0 Quick Start Guide

Get started with Ligaya's advanced type system and code generation in 5 minutes!

## Two Ways to Use Ligaya

### Option 1: Type-Safe Code Generation (Recommended) 🆕

Use `.ligaya` definition files for compile-time type safety.

### Option 2: Direct API

Use the framework API directly (traditional approach).

---

## Option 1: Type-Safe Code Generation

### Step 1: Install Lune

```bash
# Windows
irm https://github.com/lune-org/lune/releases/latest/download/lune-windows-x86_64.exe -OutFile lune.exe

# macOS
brew install lune

# Linux
curl -fsSL https://github.com/lune-org/lune/releases/latest/download/lune-linux-x86_64 -o lune
```

### Step 2: Create Definition File

Create `events.ligaya`:

```lua
-- Configuration
option WriteValidations = true

-- Events with advanced types
event PlayerDamage {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    priority: Critical,
    data: (u8(1..100), string)  -- Damage 1-100, type
}

event PlayerPosition {
    from: Client,
    type: Unreliable,
    call: ManySync,
    priority: High,
    data: (Vector3, f32)  -- Position, speed
}

-- RemoteFunction
function GetPlayerData {
    yield: Coroutine,
    data: (u32),
    return: (string, u8, u32)  -- Name, level, coins
}
```

### Step 3: Generate Code

```bash
lune run Packages/Ligaya/tools/generate.luau events.ligaya NetworkEvents.luau
```

### Step 4: Use Generated Code

```lua
local NetworkEvents = require(ReplicatedStorage.NetworkEvents)

-- SERVER
-- Type-safe! Compile-time checked!
NetworkEvents.PlayerDamageFireAll(25, "Fire")  -- ✅
-- NetworkEvents.PlayerDamageFireAll("wrong", 123)  -- ❌ Type error!

-- Listen
NetworkEvents.PlayerDamageOn(function(player, damage: number, damageType: string)
    print(`{player.Name} took {damage} {damageType} damage`)
end)

-- RemoteFunction
NetworkEvents.GetPlayerDataOn(function(player, userId: number)
    return "Player123", 50, 1000
end)

-- CLIENT
NetworkEvents.PlayerPositionFire(Vector3.new(10, 0, 20), 16)

-- RemoteFunction
local name, level, coins = NetworkEvents.GetPlayerDataInvoke(12345)
```

---

## Option 2: Direct API (Traditional)

## Installation

1. Place the Ligaya folder in your ReplicatedStorage
2. Require it from both client and server scripts

## Basic Usage

### Server Setup

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ligaya = require(ReplicatedStorage.Ligaya)

-- Initialize the framework
Ligaya:Initialize()

-- Register events
Ligaya:RegisterEvent({
    Name = "PlayerDamage",
    From = "Server",
    Type = "Reliable",
    Call = "ManyAsync",
    Priority = "High",
})

-- Fire events
Ligaya:FireAll("PlayerDamage", 25, "Fire")
Ligaya:Fire(player, "PlayerDamage", 50, "Explosion")
```

### Client Setup

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ligaya = require(ReplicatedStorage.Ligaya)

-- Initialize the framework
Ligaya:Initialize()

-- Register events (must match server)
Ligaya:RegisterEvent({
    Name = "PlayerDamage",
    From = "Server",
    Type = "Reliable",
    Call = "ManyAsync",
    Priority = "High",
})

-- Listen to events
Ligaya:On("PlayerDamage", function(damage, damageType)
    print(`Took {damage} damage from {damageType}`)
end)
```

## Advanced Features

### Using Middleware

```lua
-- Rate limiting
Ligaya:UseMiddleware(Ligaya.Middleware.RateLimit(10, 1)) -- 10 calls per second

-- Validation
Ligaya:UseMiddleware(Ligaya.Middleware.Validation(function(data)
    return type(data) == "number" and data > 0
end))

-- Logging
Ligaya:UseMiddleware(Ligaya.Middleware.Logging(true))
```

### Priority Events

```lua
Ligaya:RegisterEvent({
    Name = "CriticalUpdate",
    From = "Server",
    Type = "Reliable",
    Call = "SingleAsync",
    Priority = "Critical", -- Will be sent before Normal/Low priority events
})
```

### Compression

```lua
Ligaya:RegisterEvent({
    Name = "LargeData",
    From = "Server",
    Type = "Reliable",
    Call = "SingleAsync",
    Compress = true, -- Automatically compress large payloads
})
```

### Metrics

```lua
-- Get global metrics
local metrics = Ligaya:GetMetrics()
print("Events sent:", metrics.EventsSent)
print("Average latency:", metrics.AverageLatency)

-- Get per-event metrics
local eventMetrics = Ligaya:GetEventMetrics("PlayerDamage")
print("Calls:", eventMetrics.CallCount)
print("Average size:", eventMetrics.AverageSize)
```

## Event Configuration Options

| Option | Type | Description |
|--------|------|-------------|
| Name | string | Unique event identifier |
| From | "Server" \| "Client" | Who fires the event |
| Type | "Reliable" \| "Unreliable" | Delivery guarantee |
| Call | "SingleSync" \| "ManySync" \| "SingleAsync" \| "ManyAsync" | Handler type |
| Priority | "Low" \| "Normal" \| "High" \| "Critical" | Processing priority |
| Compress | boolean | Enable compression for large data |
| MaxSize | number | Maximum payload size in bytes |
| RateLimit | RateLimitConfig | Rate limiting configuration |

## Best Practices

1. **Initialize early** - Call `Initialize()` before registering events
2. **Match configurations** - Event configs must match between client and server
3. **Use priorities wisely** - Reserve "Critical" for truly critical events
4. **Enable compression for large data** - Automatically reduces bandwidth
5. **Monitor metrics** - Use built-in metrics to optimize performance
6. **Use middleware** - Add validation and rate limiting to prevent abuse

## Next Steps

- Learn about [Advanced Type System](./AdvancedTypeSystem.md) - Ranges, optionals, enums 🆕
- Read [RemoteFunction Guide](./RemoteFunctions.md) - Request-response pattern 🆕
- Check [Quick Reference](./QuickReference.md) - Fast syntax lookup 🆕
- See [Advanced Examples](../examples/advanced.ligaya) - All features demo 🆕
- Review [Migration from Blink](./MigrationFromBlink.md) - Switch easily 🆕
