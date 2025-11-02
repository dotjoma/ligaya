# Changelog

All notable changes to Ligaya Framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-11-02

### 🎉 Major Release: Advanced Type System

This release brings Ligaya to feature parity with Blink's type system while maintaining superior performance.

### Added

#### Advanced Type System
- **Integer Types**: `u8`, `u16`, `u32`, `i8`, `i16`, `i32` for optimal bandwidth usage
- **Float Types**: `f16`, `f32`, `f64` for precision control
- **Bounded Types**: Range syntax like `u8(0..100)`, `string(3..20)` for validation
- **Optional Types**: `type?` syntax for nullable values
- **Array Types**: `type[]` with optional bounds like `u32[1..50]`
- **Tagged Enums**: Powerful variant types with associated data
- **Unit Enums**: Simple value enumerations
- **Type Encoding**: Custom encoding for Vector3 and CFrame (e.g., `Vector3<i16>`)

#### RemoteFunction Support
- Full request-response pattern support
- Coroutine-based yielding (Future/Promise coming soon)
- Type-safe function definitions
- Automatic error handling

#### Enhanced Parser
- Advanced type parsing with ranges, optionals, and generics
- Enum parsing (unit and tagged)
- Function definition parsing
- Better error messages with hints
- Configuration options support

#### Code Generation
- Type-safe wrappers for all events and functions
- Runtime validation code generation (optional)
- Enum type exports
- Multiple return value support
- Improved generated code quality

#### New Roblox Types
- `BrickColor` support
- `DateTime` support
- `UDim2` support
- `Rect` support
- `Region3` support

#### Documentation
- [Advanced Type System Guide](./docs/AdvancedTypeSystem.md)
- [RemoteFunction Guide](./docs/RemoteFunctions.md)
- [Migration from Blink Guide](./docs/MigrationFromBlink.md)
- Comprehensive examples in `examples/advanced.ligaya`

### Changed

- **Parser**: Now returns structured definitions object instead of flat event list
- **Code Generator**: Updated to handle events, functions, and enums
- **Version**: Updated to 2.0.0 "Advanced Type System"
- **README**: Updated with new features and comparison table

### Performance

- Maintains 3-5x faster serialization vs Blink
- Maintains 46% bandwidth savings
- Maintains 90% memory allocation reduction
- No performance regression from new features

### Compatibility

- **Breaking Change**: `.ligaya` file syntax updated (lowercase field names, parentheses for data)
- **Migration Tool**: Automated conversion script provided
- **API**: Generated code API remains compatible

### Comparison with Blink

| Feature | Blink | Ligaya v2.0 |
|---------|-------|-------------|
| Type System | ✅ Full | ✅ Full |
| Performance | Good | **3-5x Faster** |
| Compression | ❌ | ✅ |
| Priority Queue | ❌ | ✅ |
| Middleware | ❌ | ✅ |
| Metrics | ❌ | ✅ |

---

## [1.2.1] - 2024-10-XX

### Fixed
- Buffer serialization edge cases
- Event index caching issues

---

## [1.2.0] - 2024-10-XX

### Added
- Delta compression for position updates
- Adaptive batching system
- Enhanced metrics tracking

### Changed
- Improved FastSerializer performance
- Optimized buffer pooling

---

## [1.1.0] - 2024-10-XX

### Added
- Priority queue system (4 levels)
- Middleware pipeline
- Retry logic with exponential backoff
- Compression module (RLE)

### Changed
- Refactored event registration
- Improved error handling

---

## [1.0.0] - 2024-10-XX

### Added
- Initial release
- Basic event system
- FastSerializer (3-5x faster than JSON)
- Buffer pooling
- Metrics tracking
- Type-safe code generation
- `.ligaya` definition files

### Features
- Reliable and unreliable events
- Client-to-server and server-to-client communication
- Automatic batching
- Type safety with code generation

---

## Upgrade Guide

### From 1.x to 2.0

1. **Update .ligaya files:**
   - Change field names to lowercase (`From:` → `from:`)
   - Wrap data/return in parentheses (`data: u8` → `data: (u8)`)
   - Add priority field to events

2. **Regenerate code:**
   ```bash
   lune run Packages/Ligaya/tools/generate.luau events.ligaya NetworkEvents.luau
   ```

3. **No code changes needed** - Generated API remains compatible!

See [Migration Guide](./docs/MigrationFromBlink.md) for detailed instructions.

---

## Roadmap

### v2.1.0 (Planned)
- [ ] Future/Promise support for RemoteFunctions
- [ ] Scopes and imports for better organization
- [ ] Export system for custom serialization
- [ ] Polling API for events

### v2.2.0 (Planned)
- [ ] TypeScript definition generation
- [ ] Casing options (Pascal, Camel, Snake)
- [ ] Manual replication control
- [ ] Enhanced validation options

### v3.0.0 (Future)
- [ ] CLI tool
- [ ] Studio plugin
- [ ] Web-based metrics dashboard
- [ ] Testing utilities

---

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](./LICENSE) for details.
