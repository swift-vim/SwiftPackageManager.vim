# Wrap SPM build system
# We call the program this.
PRODUCT=spm-vim
LAST_LOG=.build/last_build.log

PYTHON_INCLUDE=/System/Library/Frameworks/Python.framework/Versions/2.7/include/python2.7/

# For now, we don't build any of the native swift stuff
all: install

.PHONY: install
install: CONFIG=release
install: SWIFT_OPTS=--product SPMVim
install: build-impl
	@echo "Installing to /usr/local/bin/$(PRODUCT)"
	ditto .build/$(CONFIG)/$(PRODUCT) /usr/local/bin/$(PRODUCT)

.PHONY: build-impl
build-impl:
	@echo "Building.."
	@mkdir -p .build/$(CONFIG)
	@echo "" > $(LAST_LOG)
	@swift build -c $(CONFIG) $(SWIFT_OPTS) | tee -a $(LAST_LOG)
	@mv .build/$(CONFIG)/SPMVim .build/$(CONFIG)/$(PRODUCT) || true

build: CONFIG=debug
build: SWIFT_OPTS=--product SPMVim
build: build-impl

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

.PHONY: run_py
run_py: .build/swiftvim.so
	python Utils/main.py

# Build compile_commands.json
# Unfortunately, we need to clean.
# Use the last installed product incase we messed something up during
# coding.
compile_commands.json: SWIFT_OPTS=-Xswiftc -parseable-output
compile_commands.json: CONFIG=debug
compile_commands.json: clean build-impl
	cat $(LAST_LOG) | /usr/local/bin/$(PRODUCT) compile_commands



