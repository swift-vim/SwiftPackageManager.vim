# SwiftPackageManager.vim

SwiftPackageManager.vim makes using Swift with Vim awesome.

It's a command line tool and Vim plugin that makes using Vim with SPM projects
easy.

## Background

### Problem

In 2018, it's difficult to use Vim for Swift development. There are too many
plugins and build systems to create a reasonable experience solving for every
possible tooling combination.

In many scenarios, it isn't possible to implement features without making some
assumptions. We are left with very abstract tools that are too hard to
implement and use.

Additionally, it is too difficult and time consuming to maintain everything as
Xcode, Swift, Bazel, CocoaPods, Carthage, Vim and other tools in this ecosystem
evolve.

### Solution

Create a unified system under the assumption that Swift Package Manager will be
used as the package manager and build system. 

It achieves this by utilizing and enhancing existing open source plugins. It
fills existing gaps by making the assumption on SPM when needed and supports
SPM first class citizen.

**SPM is a reasonable common denominator, as it has gained momentum in the
community and is a first class citizen in swift.**

### github.com/swift-vim

swift-vim is the central organization where projects live. Development 
happens in the open.

## Non Goals

It doesn't reimplement replace language level features, like [syntax highlighting](https://github.com/keith/swift.vim), or [playgrounds](https://github.com/jerrymarino/SwiftPlayground.vim).

Xcode support. It is already possible to piece together existing tools to use Vim with Xcode projects.

## Feature Roadmap

### Code Completion and Diagnostics

Status: Working / In Progress

Support for Code Completion in Swift Package Manager Projects. The core plugin is [iCompleteMe](https://github.com/jerrymarino/iCompleteMe).

- [x] Generate Configuration for Swift Package Manager projects ( `compile_commands.json` ) 

### Build Support

Status: TODO

Integrate with Swift Package Manager's build system

- [] see build errors and warnings in Vim

### Playgrounds

Status: In Progress

Create and experiment Playgrounds with Swift Package Manager Projects.

This is fundamental playground support for Vim, and has the ability to:

- [x] Display playground output in Vim [SwiftPlayground.vim](https://github.com/jerrymarino/SwiftPlayground.vim)
- [] Generate Playgrounds
- [] Integrate Swift Package Manager dependencies into the Playground

### Debugger

Status: TODO

A lightweight "plugin" for [swift-lldb](). Support should be fast and utilize
the LLDB shell running in another process for most interaction.

Features:
- Add and remove breakpoints from vim
- When the debugger hits a breakpoint it open the file in vim at that line

### Test Support

Status: TODO

Run tests and see failing output in Vim.

### Distribution and Installation

SwiftPackageManager.vim installs with your Vim Plugin manager of choice.

## Contributing

Contributors welcome!

