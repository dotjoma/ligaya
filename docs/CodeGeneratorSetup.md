# Ligaya Code Generator - Setup Guide

Complete guide for setting up the Ligaya code generator with proper folder structure.

---

## 📁 Recommended Folder Structure

### Option 1: Ligaya as Dependency (Recommended)

```
YourGame/
├── src/
│   ├── client/
│   │   └── main.client.luau
│   ├── server/
│   │   └── main.server.luau
│   └── shared/
│       ├── events.ligaya          ← Your event definitions
│       └── NetworkEvents.luau     ← Generated code (auto-generated)
├── Packages/
│   └── Ligaya/                    ← Ligaya framework
│       ├── src/
│       ├── tools/
│       │   ├── LigayaParser.luau
│       │   └── generate.luau
│       └── init.luau
└── .ligaya/                       ← Config folder (optional)
    └── config.json
```

### Option 2: Ligaya in ReplicatedStorage

```
YourGame/
├── ReplicatedStorage/
│   ├── Ligaya/                    ← Ligaya framework
│   │   ├── src/
│   │   ├── tools/
│   │   └── init.luau
│   ├── events.ligaya              ← Your event definitions
│   └── NetworkEvents.luau         ← Generated code
├── ServerScriptService/
│   └── main.server.luau
└── StarterPlayer/
    └── StarterPlayerScripts/
        └── main.client.luau
```

### Option 3: Standalone Project

```
MyProject/
├── events.ligaya                  ← Your event definitions
├── NetworkEvents.luau             ← Generated code
└── Ligaya/                        ← Ligaya framework (cloned)
    ├── src/
    ├── tools/
    │   ├── LigayaParser.luau
    │   └── generate.luau
    └── init.luau
```

---

## 🚀 Setup Instructions

### Step 1: Install Lune

Lune is required to run the code generator CLI tool.

#### Windows (PowerShell)
```powershell
irm https://github.com/lune-org/lune/releases/latest/download/lune-windows-x86_64.exe -OutFile lune.exe
Move-Item lune.exe C:\Windows\System32\
```

#### macOS (Homebrew)
```bash
brew install lune
```

#### Linux
```bash
curl -fsSL https://github.com/lune-org/lune/releases/latest/download/lune-linux-x86_64 -o lune
chmod +x lune
sudo mv lune /usr/local/bin/
```

#### Verify Installation
```bash
lune --version
# Should output: lune x.x.x
```

---

### Step 2: Get Ligaya Framework

#### Option A: Using Wally (Recommended)
```toml
# wally.toml
[dependencies]
Ligaya = "yourusername/ligaya@1.0.0"
```

Then run:
```bash
wally install
```

#### Option B: Clone from GitHub
```bash
git clone https://github.com/yourusername/ligaya.git Packages/Ligaya
```

#### Option C: Download Release
1. Download latest release from GitHub
2. Extract to `Packages/Ligaya/`

---

### Step 3: Create Event Definitions

Create `events.ligaya` in your project:

```lua
-- events.ligaya
-- Your network event definitions

-- Combat events
event PlayerDamage {
    from: Server,
    type: Reliable,
    priority: Critical,
    data: (number, string),
}

event PlayerHeal {
    from: Server,
    type: Reliable,
    priority: High,
    data: (number),
}

-- Movement events
event PlayerPosition {
    from: Client,
    type: Unreliable,
    priority: High,
    data: (Vector3),
}

-- Chat events
event ChatMessage {
    from: Client,
    type: Reliable,
    priority: Normal,
    compress: true,
    data: (string),
}
```

---

### Step 4: Generate Code

#### From Project Root

```bash
# Basic usage
lune run Packages/Ligaya/tools/generate.luau events.ligaya NetworkEvents.luau

# With custom paths
lune run Packages/Ligaya/tools/generate.luau src/shared/events.ligaya src/shared/NetworkEvents.luau
```

#### From Ligaya Folder

```bash
cd Packages/Ligaya
lune run tools/generate.luau ../../events.ligaya ../../NetworkEvents.luau
```

#### Using Relative Paths

```bash
# If you're in YourGame/
lune run Packages/Ligaya/tools/generate.luau \
    src/shared/events.ligaya \
    src/shared/NetworkEvents.luau
```

---

### Step 5: Use Generated Code

```lua
-- src/client/main.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetworkEvents = require(ReplicatedStorage.NetworkEvents)

-- Type-safe! ✅
NetworkEvents.PlayerPositionFire(Vector3.new(10, 0, 20))

-- Listen for events
NetworkEvents.PlayerDamageOn(function(damage: number, damageType: string)
    print(`Took {damage} damage from {damageType}`)
end)
```

---

## 🔧 Configuration

### Create `.ligaya/config.json` (Optional)

```json
{
    "inputFile": "src/shared/events.ligaya",
    "outputFile": "src/shared/NetworkEvents.luau",
    "moduleName": "NetworkEvents",
    "autoGenerate": true
}
```

Then run:
```bash
lune run Packages/Ligaya/tools/generate.luau
# Uses config.json automatically
```

---

## 📝 Example Workflows

### Workflow 1: Simple Project

```
MyGame/
├── events.ligaya
├── NetworkEvents.luau (generated)
└── Ligaya/ (framework)
```

**Generate:**
```bash
lune run Ligaya/tools/generate.luau events.ligaya NetworkEvents.luau
```

---

### Workflow 2: Organized Project

```
MyGame/
├── src/
│   └── shared/
│       ├── events.ligaya
│       └── NetworkEvents.luau (generated)
└── Packages/
    └── Ligaya/
```

**Generate:**
```bash
lune run Packages/Ligaya/tools/generate.luau \
    src/shared/events.ligaya \
    src/shared/NetworkEvents.luau
```

---

### Workflow 3: Multiple Event Files

```
MyGame/
├── events/
│   ├── combat.ligaya
│   ├── movement.ligaya
│   └── chat.ligaya
├── generated/
│   ├── CombatEvents.luau (generated)
│   ├── MovementEvents.luau (generated)
│   └── ChatEvents.luau (generated)
└── Packages/
    └── Ligaya/
```

**Generate:**
```bash
# Generate all
lune run Packages/Ligaya/tools/generate.luau events/combat.ligaya generated/CombatEvents.luau
lune run Packages/Ligaya/tools/generate.luau events/movement.ligaya generated/MovementEvents.luau
lune run Packages/Ligaya/tools/generate.luau events/chat.ligaya generated/ChatEvents.luau
```

**Or create a script:**
```bash
# generate-all.sh
#!/bin/bash
for file in events/*.ligaya; do
    name=$(basename "$file" .ligaya)
    lune run Packages/Ligaya/tools/generate.luau \
        "$file" \
        "generated/${name}Events.luau"
done
```

---

## 🤖 Automation

### Option 1: NPM Scripts

Create `package.json`:
```json
{
    "scripts": {
        "generate": "lune run Packages/Ligaya/tools/generate.luau events.ligaya NetworkEvents.luau",
        "generate:watch": "nodemon --watch events.ligaya --exec npm run generate"
    }
}
```

Run:
```bash
npm run generate
npm run generate:watch  # Auto-regenerate on changes
```

---

### Option 2: Git Hooks

Create `.git/hooks/pre-commit`:
```bash
#!/bin/bash
# Auto-generate if .ligaya files changed

if git diff --cached --name-only | grep -q "\.ligaya$"; then
    echo "🔨 Regenerating network events..."
    lune run Packages/Ligaya/tools/generate.luau events.ligaya NetworkEvents.luau
    git add NetworkEvents.luau
    echo "✅ Network events regenerated"
fi
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

---

### Option 3: GitHub Actions

Create `.github/workflows/generate.yml`:
```yaml
name: Generate Network Events

on:
  push:
    paths:
      - '**.ligaya'

jobs:
  generate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Lune
        uses: lune-org/setup-lune@v1
      
      - name: Generate code
        run: |
          lune run Packages/Ligaya/tools/generate.luau \
            events.ligaya \
            NetworkEvents.luau
      
      - name: Commit changes
        uses: stefanzweifel/git-auto-commit-action@v4
        with:
          commit_message: "chore: regenerate network events"
          file_pattern: "NetworkEvents.luau"
```

---

## 🎯 Quick Start Commands

### First Time Setup

```bash
# 1. Install Lune
# (See Step 1 above for your OS)

# 2. Clone/Install Ligaya
git clone https://github.com/yourusername/ligaya.git Packages/Ligaya

# 3. Create events.ligaya
# (See Step 3 above)

# 4. Generate code
lune run Packages/Ligaya/tools/generate.luau events.ligaya NetworkEvents.luau

# 5. Done! ✅
```

### Daily Usage

```bash
# Edit events.ligaya
# Then regenerate:
lune run Packages/Ligaya/tools/generate.luau events.ligaya NetworkEvents.luau
```

---

## 🐛 Troubleshooting

### Error: "lune: command not found"

**Solution:** Lune is not installed or not in PATH.
```bash
# Reinstall Lune (see Step 1)
# Or use full path:
/path/to/lune run Packages/Ligaya/tools/generate.luau events.ligaya NetworkEvents.luau
```

---

### Error: "Input file not found"

**Solution:** Check file path is correct.
```bash
# Use absolute path
lune run Packages/Ligaya/tools/generate.luau \
    "$(pwd)/events.ligaya" \
    "$(pwd)/NetworkEvents.luau"

# Or relative from current directory
ls events.ligaya  # Verify file exists
```

---

### Error: "Parse error"

**Solution:** Check `.ligaya` file syntax.
```lua
-- ✅ Correct
event MyEvent {
    from: Server,
    type: Reliable,
    data: (number, string),
}

-- ❌ Wrong (missing comma)
event MyEvent {
    from: Server
    type: Reliable
    data: (number, string)
}
```

---

### Error: "Module not found"

**Solution:** Check Ligaya path is correct.
```bash
# Verify Ligaya exists
ls Packages/Ligaya/tools/generate.luau

# Use correct path
lune run Packages/Ligaya/tools/generate.luau events.ligaya NetworkEvents.luau
```

---

## 📚 Complete Example

### Project Structure
```
MyGame/
├── src/
│   ├── client/
│   │   └── main.client.luau
│   ├── server/
│   │   └── main.server.luau
│   └── shared/
│       ├── events.ligaya
│       └── NetworkEvents.luau (generated)
├── Packages/
│   └── Ligaya/
│       ├── src/
│       ├── tools/
│       │   ├── LigayaParser.luau
│       │   └── generate.luau
│       └── init.luau
├── package.json
└── .gitignore
```

### events.ligaya
```lua
event PlayerDamage {
    from: Server,
    type: Reliable,
    priority: Critical,
    data: (number, string),
}

event PlayerPosition {
    from: Client,
    type: Unreliable,
    priority: High,
    data: (Vector3),
}
```

### Generate Command
```bash
lune run Packages/Ligaya/tools/generate.luau \
    src/shared/events.ligaya \
    src/shared/NetworkEvents.luau
```

### Usage
```lua
-- src/client/main.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetworkEvents = require(ReplicatedStorage.shared.NetworkEvents)

NetworkEvents.PlayerPositionFire(Vector3.new(10, 0, 20))
```

---

## ✅ Checklist

Before generating code, make sure:

- [ ] Lune is installed (`lune --version`)
- [ ] Ligaya framework is in your project
- [ ] `.ligaya` file exists and has correct syntax
- [ ] Output path is writable
- [ ] You're running from correct directory

---

## 🎉 You're Ready!

Now you can:
1. ✅ Create `.ligaya` event definitions
2. ✅ Generate type-safe code
3. ✅ Use compile-time type checking
4. ✅ Enjoy safer networking!

**Happy coding!** 🚀
