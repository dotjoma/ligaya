# Upgrade Guide: v1.x to v2.0

Quick guide for upgrading from Ligaya v1.x to v2.0.

## What's New in v2.0?

### 🎉 Major Features

1. **Advanced Type System** - Blink-compatible types (u8, i16, ranges, optionals, arrays)
2. **Enums** - Unit and tagged enums for better type safety
3. **RemoteFunctions** - Type-safe request-response pattern
4. **Runtime Validation** - Optional type checking at runtime
5. **Better Code Generation** - Improved generated code quality

### ⚡ Performance (Unchanged)

All v1.x performance benefits maintained:
- 3-5x faster serialization
- 46% bandwidth savings
- 90% memory allocation reduction
- <1ms critical event latency

---

## Breaking Changes

### None! 🎉

v2.0 is **fully backward compatible** with v1.x. Your existing code will continue to work without changes.

---

## New Features You Can Use

### 1. Type-Safe Code Generation (Recommended)

**Before (v1.x):**
```lua
-- Manual registration
Ligaya:RegisterEvent({
    Name = "PlayerDamage",
    From = "Server",
    Type = "Reliable",
    Call = "ManyAsync",
    Priority = "High",
})

Ligaya:FireAll("PlayerDamage", 25, "Fire")
```

**After (v2.0):**
```lua
-- Create events.ligaya
event PlayerDamage {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    priority: Critical,
    data: (u8(1..100), string)  -- Type-safe!
}

-- Generate code
-- lune run Packages/Ligaya/tools/generate.luau events.ligaya NetworkEvents.luau

-- Use generated code
local NetworkEvents = require(ReplicatedStorage.NetworkEvents)
NetworkEvents.PlayerDamageFireAll(25, "Fire")  -- Type-safe!
```

### 2. Advanced Types

```lua
-- Bounded types
event PlayerDamage {
    data: (u8(1..100), string)  -- Damage 1-100
}

-- Optional types
event PlayerEmote {
    data: (u8, f32?)  -- Emote ID, optional duration
}

-- Arrays with bounds
event InventoryUpdate {
    data: (u32[1..50])  -- 1-50 items
}
```

### 3. Enums

```lua
-- Unit enum
enum DamageType = {
    Physical,
    Fire,
    Ice
}

-- Tagged enum
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

### 4. RemoteFunctions

```lua
-- Define function
function GetPlayerData {
    yield: Coroutine,
    data: (u32),
    return: (string, u8, u32)
}

-- Client
local name, level, coins = NetworkEvents.GetPlayerDataInvoke(userId)

-- Server
NetworkEvents.GetPlayerDataOn(function(player, userId)
    return "Player123", 50, 1000
end)
```

### 5. Runtime Validation

```lua
-- Enable in .ligaya file
option WriteValidations = true

-- Generated code includes validation
function NetworkEvents.PlayerDamageFire(player, damage, damageType)
    assert(typeof(damage) == "number")
    assert(damage >= 1 and damage <= 100)
    assert(typeof(damageType) == "string")
    -- ...
end
```

---

## Migration Steps

### Step 1: Update Version

```toml
# wally.toml
[dependencies]
Ligaya = "dotjoma/ligaya@2.0.0"
```

### Step 2: (Optional) Install Lune

Only needed if you want to use code generation:

```bash
# Windows
irm https://github.com/lune-org/lune/releases/latest/download/lune-windows-x86_64.exe -OutFile lune.exe

# macOS
brew install lune
```

### Step 3: (Optional) Create .ligaya Files

Convert your event registrations to .ligaya format:

```lua
-- Before: Manual registration
Ligaya:RegisterEvent({
    Name = "MyEvent",
    From = "Server",
    Type = "Reliable",
    Call = "ManyAsync",
})

-- After: .ligaya file
event MyEvent {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    priority: Normal,
    data: (string)
}
```

### Step 4: (Optional) Generate Code

```bash
lune run Packages/Ligaya/tools/generate.luau events.ligaya NetworkEvents.luau
```

### Step 5: Test

Run your game and verify everything works!

---

## Compatibility Matrix

| Feature | v1.x | v2.0 | Compatible? |
|---------|------|------|-------------|
| Manual Registration | ✅ | ✅ | ✅ Yes |
| Fire/FireAll/etc | ✅ | ✅ | ✅ Yes |
| On/Listen | ✅ | ✅ | ✅ Yes |
| Middleware | ✅ | ✅ | ✅ Yes |
| Metrics | ✅ | ✅ | ✅ Yes |
| Compression | ✅ | ✅ | ✅ Yes |
| Priority Queue | ✅ | ✅ | ✅ Yes |
| Code Generation | ❌ | ✅ | 🆕 New |
| Advanced Types | ❌ | ✅ | 🆕 New |
| Enums | ❌ | ✅ | 🆕 New |
| RemoteFunctions | ❌ | ✅ | 🆕 New |

---

## FAQ

### Q: Do I need to change my existing code?

**A:** No! v2.0 is fully backward compatible. Your v1.x code will work without changes.

### Q: Should I use code generation?

**A:** Recommended for new projects. It provides compile-time type safety and better developer experience.

### Q: Can I mix manual registration and code generation?

**A:** Yes! You can use both approaches in the same project.

### Q: What if I don't want to use Lune?

**A:** You can continue using manual registration like in v1.x. Code generation is optional.

### Q: Will my performance improve?

**A:** Performance is the same as v1.x (already 3-5x faster than alternatives). v2.0 adds features without performance cost.

### Q: How do I migrate from Blink?

**A:** See [Migration from Blink Guide](./docs/MigrationFromBlink.md) for detailed instructions.

---

## Resources

- [What's New in v2.0](./WHATS_NEW_V2.md) - Feature overview
- [Advanced Type System](./docs/AdvancedTypeSystem.md) - Complete type guide
- [RemoteFunction Guide](./docs/RemoteFunctions.md) - Request-response pattern
- [Quick Reference](./docs/QuickReference.md) - Fast syntax lookup
- [Migration from Blink](./docs/MigrationFromBlink.md) - Switch from Blink
- [Changelog](./CHANGELOG.md) - Version history

---

## Support

- **Issues:** [GitHub Issues](https://github.com/dotjoma/ligaya/issues)
- **Discussions:** [GitHub Discussions](https://github.com/dotjoma/ligaya/discussions)
- **Documentation:** [Full Docs](./docs/)

---

**Enjoy Ligaya v2.0! 🎉**
