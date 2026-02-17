# Contributing to Manuscript

Thank you for your interest in contributing to Manuscript! This document provides guidelines and information for contributors.

## Ways to Contribute

### Report Bugs
- Use [GitHub Issues](https://github.com/manuscriptapp/manuscript/issues) to report bugs
- Include steps to reproduce the issue
- Mention your iOS/macOS version and device

### Suggest Features
- Open an issue with the "enhancement" label
- Describe the feature and why it would be useful
- Consider how it fits with Manuscript's philosophy

### Submit Code
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly on iOS and macOS
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Improve Documentation
- Fix typos or clarify existing docs
- Add examples or tutorials
- Translate documentation

## Development Setup

### Requirements
- Xcode 16.0+
- iOS 18.0+ / macOS 15.0+ SDK
- Swift 5.9+

### Building
1. Clone the repository
2. Open `Manuscript/Manuscript.xcodeproj`
3. Select your target platform (iOS or macOS) from the scheme selector
4. Build and run (⌘R)

The project is a single multi-platform SwiftUI app supporting both iOS and macOS from one codebase.

### Project Structure
```
manuscript/
├── Manuscript/
│   ├── Manuscript.xcodeproj  # Multi-platform Xcode project
│   └── Manuscript/           # Main app code
│       ├── Models/           # Data models
│       ├── ViewModels/       # View models (MVVM)
│       ├── Views/            # SwiftUI views
│       │   └── Platform/     # Platform-specific views (iOS/macOS)
│       └── Services/         # Business logic and services
├── docs/                     # Marketing website (GitHub Pages)
└── meta/                     # Internal docs and planning
```

## Code Guidelines

### Swift Style
- Follow Swift API Design Guidelines
- Use meaningful variable and function names
- Keep functions focused and concise
- Add comments for complex logic

### Architecture
- Use SwiftUI for UI components
- Follow MVVM pattern where applicable
- Platform-specific UI in `Views/Platform/`; shared logic elsewhere
- Use `#if os(macOS)` / `#if os(iOS)` for conditional compilation

### Testing
- Write tests for new functionality
- Ensure existing tests pass before submitting PR
- Test on both iOS and macOS when possible

## Pull Request Process

1. Update documentation if needed
2. Add tests for new features
3. Ensure all tests pass
4. Update CHANGELOG.md if applicable
5. Request review from maintainers

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Assume good intentions

## Questions?

- Open an issue for questions about contributing
- Join discussions in existing issues
- Check existing documentation first

## License

By contributing, you agree that your contributions will be licensed under the MPL-2.0 License.

---

Thank you for helping make Manuscript better for everyone!
