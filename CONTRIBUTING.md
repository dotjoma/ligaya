# Contributing to Ligaya

Thank you for your interest in contributing to Ligaya! 🎉

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/ligaya.git`
3. Create a branch: `git checkout -b feature/your-feature`
4. Make your changes
5. Test your changes
6. Commit: `git commit -m "Add your feature"`
7. Push: `git push origin feature/your-feature`
8. Create a Pull Request

## Development Setup

### Prerequisites

- [Lune](https://lune-org.github.io/docs/) - For code generation
- [Roblox Studio](https://www.roblox.com/create) - For testing
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/ligaya.git
cd ligaya

# Install Lune
# See: https://lune-org.github.io/docs/getting-started/installation
```

## Project Structure

```
ligaya/
├── src/              # Core framework code
├── tools/            # Code generation tools
├── docs/             # Documentation
├── examples/         # Example code
├── tests/            # Unit tests
└── benchmarks/       # Performance benchmarks
```

## Code Style

- Use `--!strict` for all Luau files
- Use `--!native` and `--!optimize 2` for performance-critical code
- Follow existing code style
- Add type annotations
- Write clear comments

## Testing

Before submitting a PR:

1. Test in Roblox Studio
2. Run benchmarks if performance-related
3. Update documentation if needed
4. Add examples if adding new features

## Pull Request Guidelines

- Keep PRs focused on a single feature/fix
- Write clear commit messages
- Update documentation
- Add tests if applicable
- Reference related issues

## Reporting Issues

When reporting issues, include:

- Ligaya version
- Roblox Studio version
- Steps to reproduce
- Expected vs actual behavior
- Code samples if applicable

## Feature Requests

We welcome feature requests! Please:

- Check if it already exists
- Explain the use case
- Provide examples
- Consider implementation complexity

## Code of Conduct

- Be respectful and inclusive
- Help others learn
- Give constructive feedback
- Focus on the code, not the person

## Questions?

- Open an issue for bugs
- Start a discussion for questions
- Check existing documentation

Thank you for contributing! 🚀
