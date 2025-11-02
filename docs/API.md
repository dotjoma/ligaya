# Ligaya v2.0 API Reference

Complete API documentation for Ligaya Framework v2.0 with advanced type system.

## Quick Links

- [Core API](#core-api) - Initialization, events, listening
- [Server API](#server-api) - Fire events to clients
- [Client API](#client-api) - Fire events to server
- [RemoteFunction API](#remotefunction-api) - Request-response 🆕
- [Middleware](#middleware) - Extensible pipeline
- [Metrics](#metrics) - Performance monitoring
- [Type System](#type-system) - Advanced types 🆕

---

## Core API

### Initialization

#### `Ligaya:Initialize(config?)`

Initializes the Ligaya framework. Must be called before any other operations.

**Parameters:**
- `config` (optional): Configuration table

**Example:**
```lua
Ligaya:Initialize()

-- With config
Ligaya:Initialize({
    EnableCompression = true,
    EnableMetrics = true,
})
```

---

### Event Management

#### `Ligaya:RegisterEvent(config: EventConfig)`

Registers a new network event.

**Parameters:**
- `config`: Event configuration table

**EventConfig Type:**
```lua
type EventConfig = {
    Name: string,              -- Unique event identifier
    From: "Server" | "Client", -- Who fires the event
    Type: "Reliable" | "Unreliable", -- Delivery guarantee
    Call: "SingleSync" | "ManySync" | "SingleAsync" | "ManyAsync" | "Polling",
    Priority: "Low" | "Normal" | "High" | "Critical"?, -- Optional
    Compress: boolean?,        -- Enable compression
    MaxSize: number?,          -- Max payload size
    RateLimit: RateLimitConfig?, -- Rate limiting
}
```

**Example:**
```lua
Ligaya:RegisterEvent({
    Name = "PlayerDamage",
    From = "Server",
    Type = "Reliable",
    Call = "ManyAsync",
    Priority = "High",
})
```

---

### Server API

#### `Ligaya:Fire(player: Player, eventName: string, ...any)`

Fires an event to a specific player.

**Parameters:**
- `player`: Target player
- `eventName`: Name of the event
- `...`: Event data

**Example:**
```lua
Ligaya:Fire(player, "PlayerDamage", 50, "Fire")
```

---

#### `Ligaya:FireAll(eventName: string, ...any)`

Fires an event to all connected players.

**Parameters:**
- `eventName`: Name of the event
- `...`: Event data

**Example:**
```lua
Ligaya:FireAll("ServerAnnouncement", "Server restarting in 5 minutes")
```

---

#### `Ligaya:FireList(players: {Player}, eventName: string, ...any)`

Fires an event to a list of players.

**Parameters:**
- `players`: Array of target players
- `eventName`: Name of the event
- `...`: Event data

**Example:**
```lua
local teamPlayers = {player1, player2, player3}
Ligaya:FireList(teamPlayers, "TeamMessage", "Your team won!")
```

---

#### `Ligaya:FireExcept(excludePlayer: Player, eventName: string, ...any)`

Fires an event to all players except one.

**Parameters:**
- `excludePlayer`: Player to exclude
- `eventName`: Name of the event
- `...`: Event data

**Example:**
```lua
Ligaya:FireExcept(player, "PlayerLeft", player.Name)
```

---

### Client API

#### `Ligaya:Fire(eventName: string, ...any)`

Fires an event to the server.

**Parameters:**
- `eventName`: Name of the event
- `...`: Event data

**Example:**
```lua
Ligaya:Fire("ChatMessage", "Hello everyone!")
```

---

### Event Listening

#### `Ligaya:On(eventName: string, handler: Function) -> Disconnect`

Registers an event handler.

**Parameters:**
- `eventName`: Name of the event
- `handler`: Callback function

**Returns:**
- Disconnect function

**Server Example:**
```lua
local disconnect = Ligaya:On("ChatMessage", function(player: Player, message: string)
    print(`{player.Name}: {message}`)
end)

-- Later, to disconnect:
disconnect()
```

**Client Example:**
```lua
Ligaya:On("PlayerDamage", function(damage: number, damageType: string)
    print(`Took {damage} damage from {damageType}`)
end)
```

---

### Middleware

#### `Ligaya:UseMiddleware(middleware: Middleware)`

Adds middleware to the processing pipeline.

**Parameters:**
- `middleware`: Middleware function

**Example:**
```lua
Ligaya:UseMiddleware(Ligaya.Middleware.RateLimit(10, 1))
Ligaya:UseMiddleware(Ligaya.Middleware.Logging(true))
```

---

### Built-in Middleware

#### `Ligaya.Middleware.RateLimit(maxCalls: number, windowSeconds: number)`

Creates rate limiting middleware.

**Parameters:**
- `maxCalls`: Maximum calls allowed
- `windowSeconds`: Time window in seconds

**Example:**
```lua
-- Allow 10 calls per second
Ligaya:UseMiddleware(Ligaya.Middleware.RateLimit(10, 1))
```

---

#### `Ligaya.Middleware.Validation(validator: (data: any) -> boolean)`

Creates validation middleware.

**Parameters:**
- `validator`: Validation function

**Example:**
```lua
Ligaya:UseMiddleware(Ligaya.Middleware.Validation(function(data)
    return type(data[1]) == "string" and #data[1] <= 200
end))
```

---

#### `Ligaya.Middleware.Logging(verbose: boolean?)`

Creates logging middleware.

**Parameters:**
- `verbose`: Enable verbose logging (optional)

**Example:**
```lua
Ligaya:UseMiddleware(Ligaya.Middleware.Logging(true))
```

---

### Metrics

#### `Ligaya:GetMetrics() -> NetworkMetrics`

Returns global network metrics.

**Returns:**
```lua
type NetworkMetrics = {
    EventsSent: number,
    EventsReceived: number,
    BytesSent: number,
    BytesReceived: number,
    AverageLatency: number,
    PacketLoss: number,
    CompressionRatio: number,
    ErrorCount: number,
}
```

**Example:**
```lua
local metrics = Ligaya:GetMetrics()
print(`Events sent: {metrics.EventsSent}`)
print(`Average latency: {metrics.AverageLatency * 1000:.2f}ms`)
```

---

#### `Ligaya:GetEventMetrics(eventName: string) -> EventMetrics?`

Returns metrics for a specific event.

**Parameters:**
- `eventName`: Name of the event

**Returns:**
```lua
type EventMetrics = {
    CallCount: number,
    TotalBytes: number,
    AverageSize: number,
    LastCalled: number,
    Errors: number,
}
```

**Example:**
```lua
local metrics = Ligaya:GetEventMetrics("PlayerDamage")
if metrics then
    print(`Calls: {metrics.CallCount}`)
    print(`Average size: {metrics.AverageSize} bytes`)
end
```

---

## Advanced API

### Custom Middleware

Create custom middleware by following this pattern:

```lua
local function CustomMiddleware(context, next)
    -- Pre-processing
    print("Before:", context.EventName)
    
    -- Validation
    if not isValid(context.Data) then
        context.Cancel() -- Cancel the event
        return
    end
    
    -- Continue pipeline
    next()
    
    -- Post-processing
    print("After:", context.EventName)
end

Ligaya:UseMiddleware(CustomMiddleware)
```

**Context Type:**
```lua
type MiddlewareContext = {
    Player: Player?,           -- Sender (server-side only)
    EventName: string,         -- Event name
    Data: any,                 -- Event data
    Metadata: {[string]: any}, -- Custom metadata
    Cancel: () -> (),          -- Cancel function
    IsCancelled: boolean,      -- Cancellation status
}
```

---

### Priority Levels

Events can be assigned priority levels that affect processing order:

| Priority | Value | Use Case |
|----------|-------|----------|
| Critical | 0 | Server shutdown, critical alerts |
| High | 1 | Combat events, important updates |
| Normal | 2 | General gameplay events (default) |
| Low | 3 | Background updates, analytics |

**Example:**
```lua
Ligaya:RegisterEvent({
    Name = "ServerShutdown",
    Priority = "Critical", -- Processed immediately
    -- ...
})
```

---

### Compression

Enable compression for events with large payloads:

```lua
Ligaya:RegisterEvent({
    Name = "WorldData",
    Compress = true, -- Automatically compress if > 512 bytes
    -- ...
})
```

**Compression Strategies:**
- **RLE**: Run-Length Encoding (default)
- **None**: No compression

---

### Rate Limiting

Configure per-event rate limits:

```lua
Ligaya:RegisterEvent({
    Name = "ChatMessage",
    RateLimit = {
        MaxCalls = 5,      -- 5 calls
        WindowSeconds = 1, -- per second
    },
    -- ...
})
```

---

## Type Definitions

### EventConfig
```lua
type EventConfig = {
    Name: string,
    From: "Server" | "Client",
    Type: "Reliable" | "Unreliable",
    Call: "SingleSync" | "ManySync" | "SingleAsync" | "ManyAsync" | "Polling",
    Priority: "Low" | "Normal" | "High" | "Critical"?,
    Compress: boolean?,
    MaxSize: number?,
    RateLimit: RateLimitConfig?,
}
```

### RateLimitConfig
```lua
type RateLimitConfig = {
    MaxCalls: number,
    WindowSeconds: number,
}
```

### NetworkMetrics
```lua
type NetworkMetrics = {
    EventsSent: number,
    EventsReceived: number,
    BytesSent: number,
    BytesReceived: number,
    AverageLatency: number,
    PacketLoss: number,
    CompressionRatio: number,
    ErrorCount: number,
}
```

### EventMetrics
```lua
type EventMetrics = {
    CallCount: number,
    TotalBytes: number,
    AverageSize: number,
    LastCalled: number,
    Errors: number,
}
```

---

---

## RemoteFunction API 🆕

### Server-Side

#### `Ligaya:OnInvoke(functionName: string, callback: (Player, ...any) -> ...any)`

Registers a callback for RemoteFunction requests.

**Parameters:**
- `functionName`: Name of the function
- `callback`: Handler function that receives player and arguments, returns results

**Returns:**
- Disconnect function

**Example:**
```lua
NetworkEvents.GetPlayerDataOn(function(player, userId: number)
    local data = DataService:GetData(userId)
    return data.Name, data.Level, data.Coins
end)
```

### Client-Side

#### `Ligaya:InvokeServer(functionName: string, ...any): ...any`

Invokes a server function and waits for response.

**Parameters:**
- `functionName`: Name of the function
- `...`: Function arguments

**Returns:**
- Function results

**Example:**
```lua
local name, level, coins = NetworkEvents.GetPlayerDataInvoke(12345)
print(`Player: {name}, Level: {level}, Coins: {coins}`)
```

---

## Type System 🆕

### Integer Types

```lua
u8, u16, u32    -- Unsigned integers
i8, i16, i32    -- Signed integers
```

### Float Types

```lua
f16, f32, f64   -- Half, single, double precision
```

### Bounded Types

```lua
u8(0..100)      -- Range 0-100
string(3..20)   -- 3-20 characters
u32[1..50]      -- Array of 1-50 elements
```

### Optional Types

```lua
string?         -- Optional string
Vector3?        -- Optional Vector3
```

### Enums

```lua
-- Unit enum
enum DamageType = { Physical, Fire, Ice }

-- Tagged enum
enum PlayerAction = "Type" {
    Move { Position: Vector3 },
    Attack { Damage: u8 }
}
```

See [Advanced Type System Guide](./AdvancedTypeSystem.md) for complete documentation.

---

## Constants

### Version Information
```lua
Ligaya.VERSION -- "2.0.0"
Ligaya.VERSION_NAME -- "Advanced Type System"
Ligaya.PROTOCOL_VERSION -- 1
```

---

## Error Handling

Ligaya uses graceful error handling:

1. **Validation Errors**: Logged and tracked in metrics
2. **Network Errors**: Automatic retry (if configured)
3. **Serialization Errors**: Event dropped, error logged
4. **Rate Limit Errors**: Event cancelled, warning logged

**Example:**
```lua
-- Errors are automatically handled
Ligaya:Fire("InvalidEvent", invalidData)
-- Warning logged, metrics updated, execution continues
```

---

## Best Practices

### 1. Initialize Early
```lua
-- Do this first
Ligaya:Initialize()

-- Then register events
Ligaya:RegisterEvent({...})
```

### 2. Match Configurations
```lua
-- Server and client must have matching event configs
-- Server:
Ligaya:RegisterEvent({ Name = "Test", From = "Server", ... })

-- Client:
Ligaya:RegisterEvent({ Name = "Test", From = "Server", ... })
```

### 3. Use Appropriate Priorities
```lua
-- Critical: Only for truly critical events
Ligaya:RegisterEvent({ Priority = "Critical", ... })

-- Normal: Most events
Ligaya:RegisterEvent({ Priority = "Normal", ... })

-- Low: Background tasks
Ligaya:RegisterEvent({ Priority = "Low", ... })
```

### 4. Enable Compression for Large Data
```lua
Ligaya:RegisterEvent({
    Name = "LargePayload",
    Compress = true, -- Reduces bandwidth
    -- ...
})
```

### 5. Monitor Metrics
```lua
-- Regularly check performance
task.spawn(function()
    while true do
        task.wait(60)
        local metrics = Ligaya:GetMetrics()
        print(`Latency: {metrics.AverageLatency * 1000:.2f}ms`)
    end
end)
```

---

## Migration from Other Frameworks

### From Blink

```lua
-- Blink
local Net = require(ReplicatedStorage.Blink.Client)
Net.MyEvent.FireAll("data")

-- Ligaya
local Ligaya = require(ReplicatedStorage.Ligaya)
Ligaya:Initialize()
Ligaya:RegisterEvent({ Name = "MyEvent", ... })
Ligaya:FireAll("MyEvent", "data")
```

### From RemoteEvents

```lua
-- RemoteEvent
local remote = ReplicatedStorage.MyRemote
remote:FireServer("data")

-- Ligaya
Ligaya:RegisterEvent({ Name = "MyEvent", ... })
Ligaya:Fire("MyEvent", "data")
```

---

## Support

For issues, questions, or contributions:
- GitHub: [Ligaya Repository]
- Documentation: [Full Docs]
- Examples: See `/examples` folder
