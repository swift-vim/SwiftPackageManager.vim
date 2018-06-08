# SwiftPackageManager.vim

SwiftPackageManager.vim makes using Swift with Vim awesome.

![BuildAwareness](https://user-images.githubusercontent.com/1245820/41139267-6e3b29ec-6a9b-11e8-8ec2-f61dfdc64c33.png)

*Status: In progress see [TODO](https://github.com/swift-vim/SwiftPackageManager.vim/blob/master/ROADMAP.md)*

## Installing

First, install with your favorite plugin manager.

Build:
```
cd .vim/bundle
git clone https://github.com/swift-vim/SwiftPackageManager.vim.git

cd SwiftPackageManager.vim
make
```

Then, add `spm-vim` to your path:
```
ln -s $PWD/.build/debug/spm-vim /usr/local/bin/spm-vim
```

## Features

### View Swift Build Results in Vim

It listens for build updates and shows results.

```
# Pipe swift output to .build/last_build.log
swift build | tee .build/last_build.log
```

### Setup Code Completion and Diagnostics

It generates [compile_commands.json](https://github.com/jerrymarino/SwiftCompilationDatabase).

```
# Pipe *parseable* swift output to spm-vim
swift build -parseable-output  | spm-vim compile_commands
```

_Required by code completion and diagnostics engine, [iCompleteMe](https://github.com/jerrymarino/iCompleteMe)._

## Roadmap

SwiftPackageManager.vim improves and unifies many features into an easy to use plugin.

Checkout the [roadmap](https://github.com/swift-vim/SwiftPackageManager.vim/blob/master/ROADMAP.md) for more!

## Contributing

Contributions in the form of issues, documentation, PRs, bugs, or any feedback are welcome.

