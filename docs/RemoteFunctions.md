# RemoteFunction Support

Ligaya v2.0 adds full support for request-response patterns using RemoteFunctions, similar to Blink's function system.

## Table of Contents

- [Overview](#overview)
- [Defining Functions](#defining-functions)
- [Yield Types](#yield-types)
- [Usage Examples](#usage-examples)
- [Best Practices](#best-practices)
- [Comparison with Blink](#comparison-with-blink)

---

## Overview

RemoteFunctions allow clients to request data from the server and wait for a response. Unlike events (fire-and-forget), functions provide a request-response pattern.

**Key Features:**
- ✅ Type-safe requests and responses
- ✅ Multiple yield types (Coroutine, Future, Promise)
- ✅ Automatic error handling
- ✅ Full type validation support

---

## Defining Functions

### Basic Syntax

```lua
function FunctionName {
    yield: YieldType,
    data: (InputTypes),
    return: (ReturnTypes)
}
```

### Example

```lua
function GetPlayerData {
    yield: Coroutine,
    data: (u32),
    return: (string, u8, u32)
}
```

This generates:
- **Client:** `NetworkEvents.GetPlayerDataInvoke(userId: number): (string, number, number)`
- **Server:** `NetworkEvents.GetPlayerDataOn(handler: (player: Player, userId: number) -> (string, number, number))`

---

## Yield Types

### Coroutine (Default)

Standard Lua coroutine-based yielding. Blocks until response received.

```lua
function GetPlayerStats {
    yield: Coroutine,
    data: (u32),
    return: (u8, u8, u8)
}
```

**Usage:**
```lua
-- CLIENT
local health, mana, stamina = NetworkEvents.GetPlayerStatsInvoke(playerId)
print(`Health: {health}, Mana: {mana}, Stamina: {stamina}`)

-- SERVER
NetworkEvents.GetPlayerStatsOn(function(player, playerId)
    local stats = getPlayerStats(playerId)
    return stats.Health, stats.Mana, stats.Stamina
end)
```

### Future (Coming Soon)

Non-blocking future-based pattern. Requires Future library.

```lua
function GetLeaderboard {
    yield: Future,
    data: (u8),
    return: (string[], u32[])
}
```

### Promise (Coming Soon)

Promise-based pattern. Requires Promise library (evaera/Promise).

```lua
function PurchaseItem {
    yield: Promise,
    data: (u32, u8),
    return: (boolean, string?)
}
```

---

## Usage Examples

### Example 1: Get Player Data

**Definition:**
```lua
function GetPlayerData {
    yield: Coroutine,
    data: (u32),
    return: (string, u8, u32)
}
```

**Client Code:**
```lua
local NetworkEvents = require(ReplicatedStorage.NetworkEvents)

-- Invoke server
local username, level, coins = NetworkEvents.GetPlayerDataInvoke(12345)
print(`Player: {username}, Level: {level}, Coins: {coins}`)
```

**Server Code:**
```lua
local NetworkEvents = require(ReplicatedStorage.NetworkEvents)

-- Handle requests
NetworkEvents.GetPlayerDataOn(function(player, userId)
    local data = PlayerDataService:GetData(userId)
    return data.Username, data.Level, data.Coins
end)
```

### Example 2: Purchase Item

**Definition:**
```lua
function PurchaseItem {
    yield: Coroutine,
    data: (u32, u8(1..99)),
    return: (boolean, string?)
}
```

**Client Code:**
```lua
-- Try to purchase item
local success, errorMessage = NetworkEvents.PurchaseItemInvoke(itemId, quantity)

if success then
    print("Purchase successful!")
else
    warn(`Purchase failed: {errorMessage}`)
end
```

**Server Code:**
```lua
NetworkEvents.PurchaseItemOn(function(player, itemId, quantity)
    -- Validate purchase
    local playerData = getPlayerData(player)
    local itemPrice = getItemPrice(itemId)
    local totalCost = itemPrice * quantity
    
    if playerData.Coins < totalCost then
        return false, "Not enough coins"
    end
    
    if not hasInventorySpace(player, quantity) then
        return false, "Inventory full"
    end
    
    -- Process purchase
    playerData.Coins -= totalCost
    addToInventory(player, itemId, quantity)
    
    return true, nil
end)
```

### Example 3: Get Leaderboard

**Definition:**
```lua
function GetLeaderboard {
    yield: Coroutine,
    data: (u8(1..100)),
    return: (string[], u32[])
}
```

**Client Code:**
```lua
-- Get top 10 players
local names, scores = NetworkEvents.GetLeaderboardInvoke(10)

for i = 1, #names do
    print(`#{i}: {names[i]} - {scores[i]} points`)
end
```

**Server Code:**
```lua
NetworkEvents.GetLeaderboardOn(function(player, count)
    local leaderboard = LeaderboardService:GetTop(count)
    
    local names = {}
    local scores = {}
    
    for _, entry in leaderboard do
        table.insert(names, entry.Name)
        table.insert(scores, entry.Score)
    end
    
    return names, scores
end)
```

### Example 4: Trade Request

**Definition:**
```lua
function TradeRequest {
    yield: Coroutine,
    data: (u32, u32[], u32[]),
    return: (boolean, string?, u32[]?)
}
```

**Client Code:**
```lua
local targetPlayerId = 67890
local offerItems = {101, 102, 103}
local requestItems = {201, 202}

local success, message, receivedItems = NetworkEvents.TradeRequestInvoke(
    targetPlayerId,
    offerItems,
    requestItems
)

if success then
    print(`Trade completed! Received {#receivedItems} items`)
else
    warn(`Trade failed: {message}`)
end
```

**Server Code:**
```lua
NetworkEvents.TradeRequestOn(function(player, targetId, offerItems, requestItems)
    -- Validate trade
    local target = Players:GetPlayerByUserId(targetId)
    if not target then
        return false, "Target player not found", nil
    end
    
    -- Check if player has offered items
    if not hasItems(player, offerItems) then
        return false, "You don't have the offered items", nil
    end
    
    -- Check if target has requested items
    if not hasItems(target, requestItems) then
        return false, "Target doesn't have the requested items", nil
    end
    
    -- Execute trade
    removeItems(player, offerItems)
    addItems(player, requestItems)
    removeItems(target, requestItems)
    addItems(target, offerItems)
    
    return true, nil, requestItems
end)
```

---

## Best Practices

### 1. Always Handle Errors

```lua
-- ❌ Bad: No error handling
local data = NetworkEvents.GetDataInvoke(id)

-- ✅ Good: Proper error handling
local success, result = pcall(function()
    return NetworkEvents.GetDataInvoke(id)
end)

if success then
    print(`Got data: {result}`)
else
    warn(`Error: {result}`)
end
```

### 2. Use Timeouts

```lua
-- ✅ Good: Add timeout
local success, result = pcall(function()
    local thread = coroutine.running()
    local timedOut = false
    
    task.delay(5, function()
        if coroutine.status(thread) == "suspended" then
            timedOut = true
            task.spawn(thread, nil)
        end
    end)
    
    local data = NetworkEvents.GetDataInvoke(id)
    
    if timedOut then
        error("Request timed out")
    end
    
    return data
end)
```

### 3. Validate Inputs on Server

```lua
-- ✅ Good: Server-side validation
NetworkEvents.PurchaseItemOn(function(player, itemId, quantity)
    -- Validate inputs
    if itemId < 1 or itemId > 10000 then
        return false, "Invalid item ID"
    end
    
    if quantity < 1 or quantity > 99 then
        return false, "Invalid quantity"
    end
    
    -- Process purchase
    -- ...
end)
```

### 4. Return Meaningful Errors

```lua
-- ❌ Bad: Generic error
return false

-- ✅ Good: Descriptive error
return false, "Not enough coins (need 100, have 50)"
```

### 5. Use Optional Returns

```lua
-- ✅ Good: Optional error message
function PurchaseItem {
    yield: Coroutine,
    data: (u32, u8),
    return: (boolean, string?)  -- Error message only on failure
}
```

---

## Comparison with Blink

| Feature | Blink | Ligaya v2.0 |
|---------|-------|-------------|
| RemoteFunction Support | ✅ | ✅ |
| Coroutine Yield | ✅ | ✅ |
| Future Support | ✅ | 🚧 Coming Soon |
| Promise Support | ✅ | 🚧 Coming Soon |
| Type Safety | ✅ | ✅ |
| Validation | ✅ Optional | ✅ Optional |
| Performance | Good | **Same** |
| Error Handling | Manual | Manual |

---

## Advanced Features

### Multiple Return Values

```lua
function GetPlayerStats {
    yield: Coroutine,
    data: (u32),
    return: (u8, u8, u8, u8, u8)  -- HP, MP, STR, DEX, INT
}
```

### Optional Parameters

```lua
function SearchPlayers {
    yield: Coroutine,
    data: (string, u8?),  -- Query, optional max results
    return: (string[], u32[])
}
```

### Complex Return Types

```lua
function GetInventory {
    yield: Coroutine,
    data: (u32),
    return: (u32[], u8[], string[])  -- IDs, Quantities, Names
}
```

---

## Error Handling

### Client-Side

```lua
local success, result = pcall(function()
    return NetworkEvents.GetDataInvoke(id)
end)

if not success then
    warn(`RemoteFunction error: {result}`)
    -- Handle error (show UI, retry, etc.)
end
```

### Server-Side

```lua
NetworkEvents.GetDataOn(function(player, id)
    local success, data = pcall(function()
        return DataService:GetData(id)
    end)
    
    if not success then
        warn(`Error getting data for {player.Name}: {data}`)
        return nil  -- Return nil on error
    end
    
    return data
end)
```

---

## Next Steps

- [Advanced Type System](./AdvancedTypeSystem.md)
- [Enum Guide](./Enums.md)
- [Performance Optimization](./Optimizations.md)
