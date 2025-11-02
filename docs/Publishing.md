# Publishing Ligaya to Roblox

Complete guide for publishing Ligaya as a Roblox model or package.

## Method 1: Publish as Roblox Model

### Step 1: Prepare the Model

1. Open Roblox Studio
2. Create a new place or open an existing one
3. Import all Ligaya files into ReplicatedStorage (see [Installation Guide](./Installation.md))

### Step 2: Create a Model Container

1. In ReplicatedStorage, select the Ligaya folder
2. Right-click → Group as Model
3. Rename to "Ligaya Network Framework"

### Step 3: Add Model Information

1. Select the model
2. In Properties, set:
   - **Name**: `Ligaya Network Framework`
   - **Description**: Add a description (see template below)

**Description Template:**
```
Ligaya - High-Performance Networking Framework

A production-ready networking framework for Roblox featuring:
• Buffer pooling (90% less allocations)
• Priority queue (< 1ms critical events)
• Compression (60-70% bandwidth savings)
• Middleware system
• Built-in metrics

Version: 1.0.0
License: MIT
Docs: [Your GitHub URL]
```

### Step 4: Publish to Roblox

1. Select the Ligaya model
2. Right-click → "Save to Roblox"
3. Choose "Model"
4. Fill in the details:
   - **Title**: Ligaya Network Framework
   - **Description**: (Use template above)
   - **Genre**: Building
   - **Tags**: networking, framework, performance, buffer, luau
5. Click "Submit"

### Step 5: Configure Model Settings

1. Go to Roblox Creator Dashboard
2. Find your model in "Creations"
3. Set visibility:
   - **Public** - Anyone can use
   - **Private** - Only you can use
4. Enable "Allow Copying" if you want others to modify
5. Add thumbnail (optional)

---

## Method 2: Publish as Wally Package

### Step 1: Create wally.toml

Create `wally.toml` in the Ligaya root:

```toml
[package]
name = "yourusername/ligaya"
version = "1.0.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"
description = "High-performance networking framework for Roblox"
license = "MIT"
authors = ["Your Name <your.email@example.com>"]
include = ["src", "LICENSE", "README.md"]
exclude = ["examples", "tests", "benchmarks", "docs"]

[dependencies]
```

### Step 2: Prepare Package Structure

Ensure your structure matches:
```
Ligaya/
├── wally.toml
├── LICENSE
├── README.md
└── src/
    ├── init.luau
    ├── Types.luau
    ├── Client.luau
    ├── Server.luau
    └── ... (other modules)
```

### Step 3: Publish to Wally

```bash
# Login to Wally (first time only)
wally login

# Publish the package
wally publish
```

### Step 4: Verify Publication

```bash
# Search for your package
wally search ligaya

# Install in a test project
wally install yourusername/ligaya
```

---

## Method 3: Publish to GitHub

### Step 1: Create Repository

1. Go to GitHub
2. Create new repository: `ligaya-framework`
3. Initialize with README

### Step 2: Prepare Repository

```bash
# Clone your repository
git clone https://github.com/yourusername/ligaya-framework.git
cd ligaya-framework

# Copy Ligaya files
cp -r /path/to/Ligaya/* .

# Create .gitignore
cat > .gitignore << EOF
# Roblox Studio
*.rbxl
*.rbxlx
*.rbxm
*.rbxmx

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
EOF
```

### Step 3: Commit and Push

```bash
git add .
git commit -m "Initial commit: Ligaya v1.0.0"
git push origin main
```

### Step 4: Create Release

1. Go to your GitHub repository
2. Click "Releases" → "Create a new release"
3. Tag version: `v1.0.0`
4. Release title: `Ligaya v1.0.0 - Initial Release`
5. Description:

```markdown
# Ligaya v1.0.0

First stable release of Ligaya Network Framework!

## Features
- ✅ Buffer pooling (90% less allocations)
- ✅ Priority queue (< 1ms critical events)
- ✅ Compression (60-70% bandwidth savings)
- ✅ Middleware system
- ✅ Built-in metrics
- ✅ Rate limiting
- ✅ Retry logic

## Installation
See [Installation Guide](docs/Installation.md)

## Documentation
- [Quick Start](docs/QuickStart.md)
- [API Reference](docs/API.md)
- [Architecture](docs/Architecture.md)

## Benchmarks
See [Benchmark Results](docs/BenchmarkResults.md)

## Breaking Changes
None (initial release)
```

6. Attach files (optional):
   - `Ligaya.rbxm` (Roblox model file)
   - `ligaya-1.0.0.zip` (source code)

7. Click "Publish release"

---

## Method 4: Publish to Roblox Creator Store

### Step 1: Create a Plugin/Model

1. Follow Method 1 to create the model
2. Add a thumbnail image (1920x1080 recommended)
3. Add screenshots showing:
   - Code examples
   - Performance metrics
   - Feature highlights

### Step 2: Submit to Creator Store

1. Go to Roblox Creator Dashboard
2. Navigate to "Creator Store"
3. Click "Submit Asset"
4. Select your Ligaya model
5. Fill in details:
   - **Category**: Development Tools
   - **Price**: Free or set a price
   - **Tags**: networking, framework, performance
6. Submit for review

### Step 3: Wait for Approval

- Review typically takes 1-3 days
- You'll receive an email when approved
- Make any requested changes if rejected

---

## Creating a Roblox Model File (.rbxm)

### Using Roblox Studio

1. Open Roblox Studio
2. Import Ligaya into ReplicatedStorage
3. Select the Ligaya folder
4. Right-click → "Save to File"
5. Save as `Ligaya.rbxm`

### Using Rojo

```bash
# Build the model
rojo build -o Ligaya.rbxm
```

---

## Creating Documentation Site (Optional)

### Using GitHub Pages

1. Create `docs/` folder in your repository
2. Add an `index.html` or use Jekyll
3. Enable GitHub Pages in repository settings
4. Your docs will be at: `https://yourusername.github.io/ligaya-framework/`

### Using MkDocs

```bash
# Install MkDocs
pip install mkdocs mkdocs-material

# Create mkdocs.yml
cat > mkdocs.yml << EOF
site_name: Ligaya Framework
theme:
  name: material
  palette:
    primary: indigo
nav:
  - Home: index.md
  - Installation: docs/Installation.md
  - Quick Start: docs/QuickStart.md
  - API Reference: docs/API.md
  - Architecture: docs/Architecture.md
  - Benchmarks: docs/BenchmarkResults.md
EOF

# Build and serve
mkdocs serve
```

---

## Marketing Your Framework

### 1. Roblox DevForum Post

Create a post in "Resources" category:

**Title:** `[RELEASE] Ligaya - High-Performance Networking Framework`

**Content:**
```markdown
# Ligaya Network Framework

A production-ready networking framework that outperforms traditional solutions.

## Key Features
- 90% reduction in memory allocations
- < 1ms latency for critical events
- 60-70% bandwidth savings with compression
- Middleware system for validation and rate limiting
- Built-in performance metrics

## Benchmarks
[Include charts from BenchmarkResults.md]

## Installation
[Link to installation guide]

## Examples
[Include code examples]

## Links
- GitHub: [Your repo]
- Documentation: [Your docs]
- Model: [Roblox model link]
```

### 2. Social Media

- Twitter: Share benchmarks and features
- Discord: Post in Roblox development servers
- YouTube: Create tutorial videos

### 3. Create Tutorial Videos

Topics:
1. "Getting Started with Ligaya"
2. "Migrating from Blink to Ligaya"
3. "Advanced Features: Middleware and Compression"
4. "Performance Optimization with Ligaya"

---

## Maintaining Your Publication

### Version Updates

1. Update version in:
   - `wally.toml`
   - `src/init.luau` (VERSION constant)
   - `README.md`

2. Create changelog:

```markdown
# Changelog

## [1.1.0] - 2024-XX-XX
### Added
- New feature X
- New feature Y

### Changed
- Improved performance of Z

### Fixed
- Bug fix A
- Bug fix B
```

3. Publish new version:
   - Wally: `wally publish`
   - GitHub: Create new release
   - Roblox: Update model

### Responding to Issues

1. Monitor GitHub Issues
2. Respond within 24-48 hours
3. Fix critical bugs immediately
4. Plan features for next release

---

## Checklist Before Publishing

- [ ] All code is tested and working
- [ ] Documentation is complete
- [ ] Examples are included
- [ ] Benchmarks are run and documented
- [ ] README is clear and comprehensive
- [ ] LICENSE file is included
- [ ] Version numbers are consistent
- [ ] No sensitive information in code
- [ ] Code is optimized (`--!native`, `--!optimize 2`)
- [ ] All dependencies are documented

---

## Legal Considerations

### License

Include MIT License (or your choice):

```
MIT License

Copyright (c) 2024 [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

[Full MIT License text]
```

### Attribution

If using code from other sources:
- Include attribution in README
- Respect original licenses
- Document any modifications

---

## Support Channels

Set up support channels:

1. **GitHub Issues** - Bug reports and feature requests
2. **Discussions** - General questions and community
3. **Discord Server** - Real-time support (optional)
4. **Email** - Direct contact for serious issues

---

## Success Metrics

Track your framework's success:

- GitHub stars
- Wally downloads
- Roblox model favorites
- DevForum post views
- Community feedback

---

## Next Steps After Publishing

1. Monitor initial feedback
2. Fix any critical issues immediately
3. Plan roadmap for future versions
4. Engage with community
5. Create more examples and tutorials

---

Good luck with your publication! 🚀
