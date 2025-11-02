# Ligaya Architecture

## Design Philosophy

Ligaya is built on industry-standard design patterns and SOLID principles to ensure:
- **Scalability** - Easy to extend with new features
- **Maintainability** - Clean, organized code structure
- **Performance** - Optimized for high-throughput scenarios
- **Reliability** - Robust error handling and retry logic

## Core Components

### 1. Buffer Pool (Object Pool Pattern)

Manages buffer allocation and reuse to minimize garbage collection pressure.

```
┌─────────────────┐
│   Buffer Pool   │
├─────────────────┤
│ • Acquire()     │
│ • Release()     │
│ • GetStats()    │
└─────────────────┘
```

**Benefits:**
- Reduces memory allocations
- Minimizes GC pauses
- Improves frame consistency

### 2. Middleware Pipeline (Decorator Pattern)

Extensible request processing pipeline for cross-cutting concerns.

```
Request → Middleware 1 → Middleware 2 → Middleware N → Handler
          ↓              ↓              ↓
       RateLimit     Validation     Logging
```

**Built-in Middleware:**
- Rate Limiting
- Validation
- Logging
- Metrics Collection

### 3. Priority Queue (Min-Heap)

Ensures critical events are processed first.

```
┌──────────────────────┐
│   Priority Queue     │
├──────────────────────┤
│ Critical Events  [0] │
│ High Events      [1] │
│ Normal Events    [2] │
│ Low Events       [3] │
└──────────────────────┘
```

**Algorithm:** Min-heap with O(log n) insertion and removal

### 4. Compression Strategy (Strategy Pattern)

Pluggable compression algorithms for different use cases.

```
┌─────────────────────┐
│ Compression Strategy│
├─────────────────────┤
│ • RLE               │
│ • LZ4 (future)      │
│ • None              │
└─────────────────────┘
```

### 5. Metrics Collector (Observer Pattern)

Tracks performance metrics for monitoring and optimization.

```
Event Fired → Metrics Collector → Update Statistics
                    ↓
              ┌──────────────┐
              │ • EventsSent │
              │ • BytesSent  │
              │ • Latency    │
              └──────────────┘
```

### 6. Retry Manager (Command Pattern)

Handles automatic retry with exponential backoff.

```
Operation Failed → Retry Manager → Wait (backoff) → Retry
                        ↓
                   Max Attempts? → OnFailure
                        ↓
                   Success → OnSuccess
```

## Data Flow

### Client to Server

```
1. Client:Fire(event, data)
2. → Priority Queue (based on event priority)
3. → Middleware Pipeline (validation, rate limit)
4. → Serialization (buffer writing)
5. → Compression (if enabled)
6. → Batching (combine multiple events)
7. → RemoteEvent:FireServer()
8. → Server receives and processes
```

### Server to Client

```
1. Server:Fire(player, event, data)
2. → Per-Player Priority Queue
3. → Middleware Pipeline
4. → Serialization
5. → Compression (if enabled)
6. → Batching (per-player)
7. → RemoteEvent:FireClient()
8. → Client receives and dispatches
```

## Memory Management

### Buffer Lifecycle

```
1. Acquire from pool
2. Write event data
3. Send over network
4. Release back to pool
5. Reuse for next event
```

### Pooling Strategy

- **Small buffers (< 2KB)**: Pooled and reused
- **Large buffers (> 2KB)**: Created on-demand, GC'd after use
- **Pool size**: Dynamically adjusts based on usage

## Performance Optimizations

### 1. Batching
Multiple events are combined into a single RemoteEvent call per frame.

### 2. Priority Scheduling
Critical events bypass the queue and are sent immediately.

### 3. Compression
Large payloads are automatically compressed to reduce bandwidth.

### 4. Buffer Pooling
Eliminates allocation overhead for common buffer sizes.

### 5. Native Compilation
Uses `--!native` and `--!optimize 2` for maximum performance.

## Comparison with Blink

| Feature | Blink | Ligaya |
|---------|-------|--------|
| Buffer Pooling | ❌ | ✅ |
| Middleware | ❌ | ✅ |
| Priority Queue | ❌ | ✅ |
| Compression | ❌ | ✅ |
| Retry Logic | ❌ | ✅ |
| Metrics | ❌ | ✅ |
| Rate Limiting | ❌ | ✅ |
| Type Safety | Compile-time | Runtime + Compile-time |

## Extensibility

### Adding Custom Middleware

```lua
local function CustomMiddleware(context, next)
    -- Pre-processing
    print("Before:", context.EventName)
    
    -- Continue pipeline
    next()
    
    -- Post-processing
    print("After:", context.EventName)
end

Ligaya:UseMiddleware(CustomMiddleware)
```

### Custom Compression Strategy

```lua
local CustomCompression = {}

function CustomCompression:Compress(data)
    -- Your compression logic
    return compressedData
end

function CustomCompression:Decompress(data)
    -- Your decompression logic
    return originalData
end

function CustomCompression:ShouldCompress(size)
    return size > 1024
end
```

## Thread Safety

Ligaya is designed for single-threaded use within Roblox's execution model:
- All operations are synchronous within a frame
- Async handlers use Roblox's task scheduler
- No manual thread management required

## Error Handling

### Graceful Degradation

```
Error Occurs → Log Warning → Continue Processing
                    ↓
              Metrics Updated (ErrorCount++)
                    ↓
              Optional Retry (if configured)
```

### Error Categories

1. **Serialization Errors** - Invalid data types
2. **Network Errors** - Connection issues
3. **Validation Errors** - Middleware rejection
4. **Rate Limit Errors** - Too many requests

All errors are logged and tracked in metrics for debugging.
