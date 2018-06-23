SHELL=bash

PLUGIN_NAME=SPMVimPlugin
PRODUCT=spm-vim
LAST_LOG=.build/last_build.log
PWD=$(shell pwd)
TRIPPLE=x86_64-apple-macosx10.12
CONFIG=
BUILD_DIR=.build/debug
EXTRA_OPTS=

default: debug

all: CONFIG=debug

.PHONY: debug
debug: CONFIG=debug
debug: cli plugin_so

.PHONY: plugin
plugin: CONFIG=debug
plugin: plugin_so


.PHONY: release
release: CONFIG=release
release: cli plugin_so

# Begin SwiftForVim ( note this is somewhat changed )

BASE_OPTS=-Xcc -I$(PYTHON_INCLUDE) \
	-Xcc -DVIM_PLUGIN_NAME=$(PLUGIN_NAME) \
	-Xlinker $(PYTHON_LINKED_LIB) \
	-Xcc -fvisibility=hidden \
	-Xlinker -undefined -Xlinker dynamic_lookup \
	-Xlinker -all_load

# Build namespaced versions of Vim and VimAsync libs.
# The modules have a prefix of the plugin name, to avoid conflicts
# when the code is linked into the Vim process.
# The module is imported as "import $(PLUGIN_NAME)Vim"
# FIXME: Consider other ways to do this that work transitively

$(BUILD_DIR)/libVim.dylib: SWIFT_OPTS=--product Vim \
	-Xswiftc -module-name=$(PLUGIN_NAME)Vim \
	-Xswiftc -module-link-name=$(PLUGIN_NAME)Vim \
	$(BASE_OPTS)
$(BUILD_DIR)/libVim.dylib:
$(BUILD_DIR)/lib$(PLUGIN_NAME)Vim.dylib: $(BUILD_DIR)/libVim.dylib
	@ditto $(BUILD_DIR)/Vim.swiftmodule \
		$(BUILD_DIR)/$(PLUGIN_NAME)Vim.swiftmodule
	@ditto $(BUILD_DIR)/Vim.swiftdoc \
		$(BUILD_DIR)/$(PLUGIN_NAME)Vim.swiftdoc
	@ditto $(BUILD_DIR)/libVim.dylib \
		$(BUILD_DIR)/lib$(PLUGIN_NAME)Vim.dylib

$(BUILD_DIR)/libVimAsync.dylib: SWIFT_OPTS=--product VimAsync  \
	-Xswiftc -module-name=$(PLUGIN_NAME)VimAsync \
	-Xswiftc -module-link-name=$(PLUGIN_NAME)VimAsync \
	$(BASE_OPTS)
$(BUILD_DIR)/libVimAsync.dylib:
$(BUILD_DIR)/lib$(PLUGIN_NAME)VimAsync.dylib: $(BUILD_DIR)/libVimAsync.dylib
	@ditto $(BUILD_DIR)/VimAsync.swiftmodule \
		$(BUILD_DIR)/$(PLUGIN_NAME)VimAsync.swiftmodule
	@ditto $(BUILD_DIR)/VimAsync.swiftdoc \
		$(BUILD_DIR)/$(PLUGIN_NAME)VimAsync.swiftdoc
	@ditto $(BUILD_DIR)/libVimAsync.dylib \
		$(BUILD_DIR)/lib$(PLUGIN_NAME)VimAsync.dylib

# Main plugin lib
.PHONY: plugin_lib
plugin_lib: SWIFT_OPTS=--product $(PLUGIN_NAME) \
		$(BASE_OPTS) 
plugin_lib: $(BUILD_DIR)/lib$(PLUGIN_NAME)Vim.dylib $(BUILD_DIR)/lib$(PLUGIN_NAME)VimAsync.dylib

# Build the .so, which Vim dynamically links.
.PHONY: plugin_so
plugin_so: plugin_lib  
	@clang -g \
		-Xlinker $(PYTHON_LINKED_LIB) \
		-Xlinker $(BUILD_DIR)/lib$(PLUGIN_NAME).dylib \
		-Xlinker $(BUILD_DIR)/lib$(PLUGIN_NAME)VimAsync.dylib \
		-Xlinker $(BUILD_DIR)/lib$(PLUGIN_NAME)Vim.dylib \
		-shared -o .build/$(PLUGIN_NAME).so

# Build for the python dylib vim links
.PHONY: py_vars
py_vars:
	@source VimUtils/make_lib.sh; python_info
	$(eval PYTHON_LINKED_LIB=$(shell source VimUtils/make_lib.sh; linked_python))
	$(eval PYTHON_INCLUDE=$(shell source VimUtils/make_lib.sh; python_inc_dir))

# SPM Build
$(BUILD_DIR)/libVim.dylib $(BUILD_DIR)/libVimAsync.dylib plugin_lib test_b: py_vars
	@echo "Building.."
	@mkdir -p .build
	@swift build -c $(CONFIG) \
	   	$(BASE_OPTS) $(SWIFT_OPTS) $(EXTRA_OPTS) \
	  	-Xswiftc -target -Xswiftc $(TRIPPLE) \
	   	| tee $(LAST_LOG)

# Mark - Internal Utils:

# Overriding Python:
# USE_PYTHON=/usr/local/Cellar/python/3.6.4_4/Frameworks/Python.framework/Versions/3.6/Python make test 
.PHONY: test
test: CONFIG=debug
test: debug
	@echo "Testing.."
	@mkdir -p .build
	@swift build --target SPMVimTests \
	   	$(BASE_OPTS) $(SWIFT_OPTS) $(EXTRA_OPTS) \
	  	-Xswiftc -target -Xswiftc $(TRIPPLE)
	@swift test --skip-build | tee $(LAST_LOG)

# End SwiftForVim

.PHONY: cli
cli: SWIFT_OPTS=--product SPMVim
cli: build_impl
	@mv .build/$(CONFIG)/SPMVim .build/$(CONFIG)/$(PRODUCT) || true

# SPM Build
.PHONY: build_impl
# Careful: assume we need to depend on this here
build_impl: py_vars
build_impl:
	@echo "Building.."
	@mkdir -p .build/$(CONFIG)
	@swift build -c $(CONFIG) $(SWIFT_OPTS) \
	  	-Xswiftc "-target"  -Xswiftc "x86_64-apple-macosx10.12" \
	   	| tee $(LAST_LOG)

# Build and install the command line program
.PHONY: install_cli
install_cli: CONFIG=release
install_cli: cli
	@echo "Installing to /usr/local/bin/$(PRODUCT)"
	ln -s $(PWD)/.build/$(CONFIG)/$(PRODUCT) /usr/local/bin/$(PRODUCT)


# Running: Pipe the parseable output example to the program
.PHONY: run
run: CONFIG=debug
run: build_impl
	cat Examples/parseable-output-example.txt | .build/$(CONFIG)/$(PRODUCT) log

.PHONY: run_compile_commands
run_compile_commands: CONFIG=debug
run_compile_commands: build_impl
	.build/$(CONFIG)/$(PRODUCT) compile_commands Examples/parseable-output-example.txt 

.PHONY: clean
clean:
	rm -rf .build/debug/*
	rm -rf .build/release/*

.PHONY: run_py
run_py: .build/spmvim.so
	python Utils/main.py


# Build compile_commands.json
# Unfortunately, we need to clean.
# Use the last installed product incase we messed something up during
# coding.
compile_commands.json: SWIFT_OPTS=-Xswiftc -parseable-output \
	-Xcc -I$(PYTHON_INCLUDE) \
	-Xlinker $(PYTHON_LINKED_LIB) 
compile_commands.json: CONFIG=debug
compile_commands.json: clean build_impl
	cat $(LAST_LOG) | /usr/local/bin/$(PRODUCT) compile_commands

.PHONY: reset
reset:
	killall spm-vim
	killall vim

.PHONY: push_error
push_error:
	cat Examples/failing_build.log > .build/last_build.log

.PHONY: clear_error
clear_error:
	echo "" > .build/last_build.log

.PHONY: pe
pe: push_error

.PHONY: ce
ce: clear_error

stress:
	for i in $$(seq 1 15); do make pe && make ce && sleep 1; done

killvim:
	for p in $$(ps aux | grep vim | awk ' { print $$2 }' ); do kill -9 $$p; done
