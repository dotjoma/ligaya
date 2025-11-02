# Advanced Type System

Ligaya Framework v2.0 introduces a powerful type system inspired by Blink but with additional features and optimizations.

## Table of Contents

- [Basic Types](#basic-types)
- [Integer Types](#integer-types)
- [Floating Point Types](#floating-point-types)
- [Bounded Types (Ranges)](#bounded-types-ranges)
- [Optional Types](#optional-types)
- [Array Types](#array-types)
- [Roblox Types](#roblox-types)
- [Enums](#enums)
- [Type Validation](#type-validation)

---

## Basic Types

```lua
-- Primitive types
string      -- Text
number      -- Lua number
boolean     -- true/false
```

## Integer Types

### Unsigned Integers (u8, u16, u32)

```lua
u8          -- 0 to 255 (1 byte)
u16         -- 0 to 65,535 (2 bytes)
u32         -- 0 to 4,294,967,295 (4 bytes)
```

**Example:**
```lua
event PlayerLevel {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    priority: Normal,
    data: (u8)  -- Level 0-255
}
```

### Signed Integers (i8, i16, i32)

```lua
i8          -- -128 to 127 (1 byte)
i16         -- -32,768 to 32,767 (2 bytes)
i32         -- -2,147,483,648 to 2,147,483,647 (4 bytes)
```

**Example:**
```lua
event TemperatureUpdate {
    from: Server,
    type: Unreliable,
    call: ManySync,
    priority: Low,
    data: (i16)  -- Temperature in Celsius
}
```

## Floating Point Types

```lua
f16         -- Half precision (2 bytes)
f32         -- Single precision (4 bytes)
f64         -- Double precision (8 bytes)
```

**Example:**
```lua
event PlayerSpeed {
    from: Server,
    type: Unreliable,
    call: ManySync,
    priority: High,
    data: (f32)  -- Speed multiplier
}
```

## Bounded Types (Ranges)

### Full Range (min..max)

```lua
u8(0..100)      -- Health: 0 to 100
u16(1..1000)    -- Item ID: 1 to 1000
f32(0..1)       -- Percentage: 0.0 to 1.0
```

**Example:**
```lua
event PlayerDamage {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    priority: Critical,
    data: (u8(1..100), string)  -- Damage 1-100, damage type
}
```

### Half Range

```lua
u8(10..)        -- Minimum 10, no maximum
u8(..100)       -- Maximum 100, no minimum
```

### Exact Value

```lua
u8(50)          -- Exactly 50
```

### String Length Bounds

```lua
string(3..20)   -- Username: 3-20 characters
string(1..200)  -- Chat message: 1-200 characters
string(36)      -- UUID: exactly 36 characters
```

**Example:**
```lua
event PlayerChat {
    from: Client,
    type: Reliable,
    call: ManyAsync,
    priority: Normal,
    data: (string(1..200))  -- Chat message
}
```

## Optional Types

Add `?` to make any type optional:

```lua
string?         -- Optional string
u8?             -- Optional u8
Vector3?        -- Optional Vector3
u8(0..100)?     -- Optional bounded u8
```

**Example:**
```lua
event PlayerEmote {
    from: Client,
    type: Reliable,
    call: ManyAsync,
    priority: Low,
    data: (u8, f32?)  -- Emote ID, optional duration
}
```

## Array Types

### Unbounded Arrays

```lua
number[]        -- Array of numbers
string[]        -- Array of strings
Vector3[]       -- Array of Vector3
```

### Bounded Arrays

```lua
u32[1..50]      -- Array of 1-50 u32 values
string[5]       -- Array of exactly 5 strings
u8[..100]       -- Array of up to 100 u8 values
```

**Example:**
```lua
event InventoryUpdate {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    priority: High,
    data: (u32[1..50])  -- Item IDs (1-50 items)
}
```

## Roblox Types

### Basic Roblox Types

```lua
Vector3         -- 3D vector
Vector2         -- 2D vector
CFrame          -- Coordinate frame
Color3          -- RGB color
Instance        -- Roblox instance
BrickColor      -- Brick color
DateTime        -- Date and time
UDim2           -- UI dimension
Rect            -- Rectangle
Region3         -- 3D region
```

**Example:**
```lua
event TeleportPlayer {
    from: Server,
    type: Reliable,
    call: SingleAsync,
    priority: Critical,
    data: (CFrame, boolean?)  -- Destination, fade effect
}
```

### Vector3 with Encoding

```lua
Vector3<i16>    -- Vector3 encoded as i16 (smaller, less precise)
Vector3<f32>    -- Vector3 encoded as f32 (default)
```

### CFrame with Encoding

```lua
CFrame<i16, f16>    -- Position: i16, Rotation: f16
```

## Enums

### Unit Enums (Simple Values)

```lua
enum DamageType = {
    Physical,
    Fire,
    Ice,
    Lightning,
    Poison
}
```

**Generated Luau Type:**
```lua
export type DamageType = "Physical" | "Fire" | "Ice" | "Lightning" | "Poison"
```

### Tagged Enums (Variants with Data)

```lua
enum PlayerAction = "Type" {
    Move {
        Position: Vector3,
        Speed: f32
    },
    Attack {
        Target: u16,
        Damage: u8(1..100),
        DamageType: string
    },
    UseItem {
        ItemId: u32,
        Quantity: u8(1..99)
    }
}
```

**Generated Luau Type:**
```lua
export type PlayerAction =
    | { Type: "Move", Position: Vector3, Speed: number }
    | { Type: "Attack", Target: number, Damage: number, DamageType: string }
    | { Type: "UseItem", ItemId: number, Quantity: number }
```

## Type Validation

Enable runtime type validation with the `WriteValidations` option:

```lua
option WriteValidations = true
```

This generates validation code that checks:
- Type correctness
- Range bounds
- Array length bounds
- String length bounds

**Example Generated Code:**
```lua
function NetworkEvents.PlayerDamageFire(player: Player, param1: number, param2: string)
    assert(typeof(param1) == "number", "Expected number, got " .. typeof(param1))
    assert(param1 >= 1 and param1 <= 100, "Value out of range [1..100]")
    assert(typeof(param2) == "string", "Expected string, got " .. typeof(param2))
    Ligaya:Fire(player, "PlayerDamage", param1, param2)
end
```

---

## Comparison with Blink

| Feature | Blink | Ligaya v2.0 |
|---------|-------|-------------|
| Integer Types | ✅ u8, u16, u32, i8, i16, i32 | ✅ Same |
| Float Types | ✅ f16, f32, f64 | ✅ Same |
| Ranges | ✅ Full, Half, Exact | ✅ Same |
| Optionals | ✅ type? | ✅ Same |
| Arrays | ✅ type[] with bounds | ✅ Same |
| Enums | ✅ Unit & Tagged | ✅ Same |
| Validation | ✅ Optional | ✅ Optional |
| Performance | Good | **3-5x Faster** |
| Compression | ❌ | ✅ Built-in |
| Priority Queue | ❌ | ✅ 4 Levels |

---

## Best Practices

### 1. Use Appropriate Integer Sizes

```lua
-- ❌ Bad: Wastes bandwidth
data: (u32, u32, u32)  -- 12 bytes

-- ✅ Good: Optimized
data: (u8, u16, u8)    -- 4 bytes
```

### 2. Bound Your Types

```lua
-- ❌ Bad: No bounds
data: (number, string)

-- ✅ Good: Bounded
data: (u8(0..100), string(1..200))
```

### 3. Use Optionals Wisely

```lua
-- ❌ Bad: Always sending nil
data: (string?, string?, string?)

-- ✅ Good: Only optional when needed
data: (string, string, string?)
```

### 4. Choose Right Float Precision

```lua
-- ❌ Bad: Overkill for simple values
data: (f64, f64)  -- 16 bytes

-- ✅ Good: Appropriate precision
data: (f32, f32)  -- 8 bytes
```

---

## Examples

### Combat System

```lua
enum DamageType = {
    Physical,
    Magical,
    True
}

event DealDamage {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    priority: Critical,
    data: (u16, u8(1..100), string)  -- Target, Damage, Type
}
```

### Inventory System

```lua
event InventoryUpdate {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    priority: High,
    data: (u32[1..50], u8[1..50])  -- Item IDs, Quantities
}
```

### Movement System

```lua
event PlayerMove {
    from: Client,
    type: Unreliable,
    call: ManySync,
    priority: High,
    data: (Vector3, f32)  -- Position, Speed
}
```

---

## Next Steps

- [RemoteFunction Guide](./RemoteFunctions.md)
- [Enum Guide](./Enums.md)
- [Performance Optimization](./Optimizations.md)
