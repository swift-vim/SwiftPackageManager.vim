# SwiftPackageManager.vim

SwiftPackageManager.vim makes using Swift with Vim awesome.

It's a command line tool and Vim plugin that's easy to use.

*Status: In progress see [Feature Roadmap](#feature-roadmap)*

## Background

### Problem

In 2018, it's difficult to use Vim for Swift development. There are too many
plugins and build systems to create a reasonable experience solving for every
possible tooling combination.

In many scenarios, it isn't possible to implement features without making some
assumptions. The result is abstract tools that are to implement and use.

Additionally, it is difficult and time consuming to maintain everything as
Xcode, Swift, Bazel, CocoaPods, Carthage, Vim and other tools in this ecosystem
evolve.

### Solution

Create a unified system under the assumption that [Swift Package
Manager](https://github.com/apple/swift-package-manager) will be used as the
package manager and build system. 

It achieves this by utilizing and enhancing existing open source plugins. It
fills existing gaps by making the assumption on SPM when needed and supports
SPM as a first class citizen.

*SPM is a reasonable common denominator, as it has gained momentum in the
community and is a first class citizen in swift.*

### github.com/swift-vim

- [swift-vim](https://github.com/swift-vim/SwiftPackageManager.vim) is the central organization where projects live. Development happens in the open.

## Non Goals

It doesn't reimplement language level features, like [syntax highlighting](https://github.com/keith/swift.vim), or [playgrounds](https://github.com/jerrymarino/SwiftPlayground.vim).

Xcode support. It is already possible to set this up with existing tools.

## Feature Roadmap

### Code Completion and Diagnostics

*Status: Working / In Progress*

Support for Code Completion in Swift Package Manager Projects.

- [x] Invoke completions and display real time diagnostics via [iCompleteMe](https://github.com/jerrymarino/iCompleteMe).
- [x] Generate `compile_commands.json` for Swift Package Manager projects via [SwiftCompilationDatabase](https://github.com/jerrymarino/SwiftCompilationDatabase)

### Playgrounds

*Status: In Progress*

Create and experiment with Playgrounds for Swift Package Manager Projects.

This is fundamental playground support for Vim, and has the ability to:

- [x] Display playground output in Vim via [SwiftPlayground.vim](https://github.com/jerrymarino/SwiftPlayground.vim)
- [ ] Generate Playgrounds
- [ ] Easily access SPM dependencies in playgrounds

### Build Support

*Status: TODO*

Integrate with Swift Package Manager's build system

- [ ] See build errors and warnings in Vim

### Debugger

*Status: TODO*

A lightweight "plugin" for [swift-lldb](https://github.com/apple/swift-lldb). Support should be fast and utilize
the LLDB shell running in another process for most interaction.

Features:
- [ ] Add and remove breakpoints from Vim
- [ ] When the debugger hits a breakpoint it open the file in Vim at that line

### Test Support

*Status: TODO*

Run tests and see failing output in Vim.

## Contributing

Contributions in the form of issues, documentation, PRs, bugs, or any feedback are welcome.

