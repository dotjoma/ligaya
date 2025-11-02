# Ligaya Quick Start Guide

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

- Read the [Architecture Guide](./Architecture.md) to understand the framework
- Check out [Advanced Usage](./AdvancedUsage.md) for complex scenarios
- See [Performance Tips](./Performance.md) for optimization strategies
