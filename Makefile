SHELL=bash

PRODUCT=spm-vim
LAST_LOG=.build/last_build.log

default: debug

all: CONFIG=debug

# FIXME: the .dylib is not being built in release..
.PHONY: release
release: CONFIG=release
release: cli .build/swiftvim.so

.PHONY: debug
debug: CONFIG=debug
debug: cli .build/swiftvim.so

.PHONY: plugin
plugin: CONFIG=debug
plugin: .build/swiftvim.so

# Dynamically find python vars
# Note, that this is OSX specific
# We will pass this directly to the linker command line
# Whatever dylib was used i.e. Py.framework/SOMEPYTHON
.PHONY: py_vars
py_vars:
	@source Utils/make_lib.sh; python_info
	$(eval PYTHON_LINKED_LIB=$(shell source Utils/make_lib.sh; linked_python))
	$(eval PYTHON_INCLUDE=$(shell source Utils/make_lib.sh; python_inc_dir))

.PHONY: cli
cli: SWIFT_OPTS=--product SPMVim
cli: build-impl
	@mv .build/$(CONFIG)/SPMVim .build/$(CONFIG)/$(PRODUCT) || true

# SPM Build
.PHONY: build-impl
# Careful: assume we need to depend on this here
build-impl: py_vars
build-impl:
	@echo "Building.."
	@mkdir -p .build/$(CONFIG)
	@echo "" > $(LAST_LOG)
	@swift build -c $(CONFIG) $(SWIFT_OPTS) | tee -a $(LAST_LOG)

# Build and install the command line program
.PHONY: install_cli
install_cli: CONFIG=release
install_cli: cli
	@echo "Installing to /usr/local/bin/$(PRODUCT)"
	ditto .build/$(CONFIG)/$(PRODUCT) /usr/local/bin/$(PRODUCT)


.PHONY: test
test: CONFIG=debug
test: SWIFT_OPTS= \
	-DSPMVIM_LOADSTUB_RUNTIME \
	-Xcc -I$(PYTHON_INCLUDE) \
	-Xlinker $(PYTHON_LINKED_LIB)  
test:
	@echo "Testing.."
	@mkdir -p .build/$(CONFIG)
	@echo "" > $(LAST_LOG)
	@swift test -c $(CONFIG) $(SWIFT_OPTS) | tee -a $(LAST_LOG)

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
.PHONY: vimcore
vimcore:
vimcore: SWIFT_OPTS=--product VimCore \
	-Xcc -I$(PYTHON_INCLUDE) \
	-Xlinker $(PYTHON_LINKED_LIB)
vimcore:  build-impl

# FIXME: Consider moving this into SPM
.build/swiftvim.so: Sources/*.c vimcore
	@clang Sources/swiftvim.c -shared -o .build/swiftvim.so \
		$(PYTHON_LINKED_LIB) \
		-I$(PYTHON_INCLUDE) \
		$(PWD)/.build/$(CONFIG)/libVimCore.dylib

.PHONY: run_py
run_py: .build/swiftvim.so
	python Utils/main.py

# Build compile_commands.json
# Unfortunately, we need to clean.
# Use the last installed product incase we messed something up during
# coding.
compile_commands.json: SWIFT_OPTS=-Xswiftc -parseable-output \
	-Xcc -I$(PYTHON_INCLUDE) \
	-Xlinker $(PYTHON_LINKED_LIB) 
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
