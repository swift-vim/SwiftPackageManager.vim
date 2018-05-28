PRODUCT=spm-vim
LAST_LOG=.build/last_build.log

# FIXME: Dynamically determine reasonable versions
PYTHON_INCLUDE=/System/Library/Frameworks/Python.framework/Versions/2.7/include/python2.7/

.PHONY: install
install: CONFIG=release
install: SWIFT_OPTS=--product SPMVim
install: build-impl
	@echo "Installing to /usr/local/bin/$(PRODUCT)"
	ditto .build/$(CONFIG)/$(PRODUCT) /usr/local/bin/$(PRODUCT)

all: build plugin

.PHONY: build-impl
build-impl:
	@echo "Building.."
	@mkdir -p .build/$(CONFIG)
	@echo "" > $(LAST_LOG)
	@swift build -c $(CONFIG) $(SWIFT_OPTS) | tee -a $(LAST_LOG)

build: CONFIG=debug
build: SWIFT_OPTS=--product SPMVim
build: build-impl
	@mv .build/$(CONFIG)/SPMVim .build/$(CONFIG)/$(PRODUCT) || true

.PHONY: test
test: CONFIG=debug
test: SWIFT_OPTS= \
	-Xcc -I -Xcc $(PYTHON_INCLUDE) -Xlinker -framework -Xlinker Python -Xcc -DSPMVIM_LOADSTUB_RUNTIME
test:
	@echo "Testing.."
	@mkdir -p .build/$(CONFIG)
	@echo "" > $(LAST_LOG)
	@swift test -c $(CONFIG) $(SWIFT_OPTS) | tee -a $(LAST_LOG)

.PHONY: release
release: CONFIG=release
release: SWIFT_OPTS=--product SPMVim
release: build-impl

# Running: Pipe the parseable output example to the program
.PHONY: run
run: CONFIG=debug
run: build-impl
	cat Examples/parseable-output-example.txt | .build/$(CONFIG)/$(PRODUCT) log

.PHONY: run_compile_commands
run_compile_commands: CONFIG=debug
run_compile_commands: build-impl
	.build/$(CONFIG)/$(PRODUCT) compile_commands Examples/parseable-output-example.txt 

.PHONY: clean
clean:
	rm -rf .build/debug/*
	rm -rf .build/release/*

# This is the core python module
# FIXME: Consider moving this into SPM
.build/swiftvim.so: SWIFT_OPTS=--product VimCore  \
	-Xcc -I -Xcc $(PYTHON_INCLUDE) -Xlinker -framework -Xlinker Python 
.build/swiftvim.so: CONFIG=debug
.build/swiftvim.so: Sources/*.c build-impl
	clang Sources/swiftvim.c -shared -o .build/swiftvim.so  -framework Python -I $(PYTHON_INCLUDE) $(PWD)/.build/$(CONFIG)/libVimCore.dylib

plugin: .build/swiftvim.so

.PHONY: run_py
run_py: .build/swiftvim.so
	python Utils/main.py

# Build compile_commands.json
# Unfortunately, we need to clean.
# Use the last installed product incase we messed something up during
# coding.
compile_commands.json: SWIFT_OPTS=-Xswiftc -parseable-output \
	-Xcc -I -Xcc $(PYTHON_INCLUDE) -Xlinker -framework -Xlinker Python
compile_commands.json: CONFIG=debug
compile_commands.json: clean build-impl
	cat $(LAST_LOG) | /usr/local/bin/$(PRODUCT) compile_commands

.PHONY: reset
reset:
	killall spm-vim
	killall vim

.PHONY: push_error
push_error:
	cat Examples/failing_build.log > .build/last_build.log
