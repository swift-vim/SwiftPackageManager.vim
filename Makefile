# Wrap SPM build system
# We call the program this.
PRODUCT=spm-vim
LAST_LOG=.build/$(CONFIG)/last.log

.PHONY: install
install: CONFIG=release
install: build-impl
	@echo "Installing to /usr/local/bin/$(PRODUCT)"
	ditto .build/$(CONFIG)/$(PRODUCT) /usr/local/bin/$(PRODUCT)

.PHONY: build-impl
build-impl:
	@echo "Building.."
	@swift build -c $(CONFIG) $(SWIFT_OPTS) | tee -a $(LAST_LOG)
	@mv .build/$(CONFIG)/SPMVim .build/$(CONFIG)/$(PRODUCT)

build: CONFIG=debug
build: build-impl

.PHONY: release
release: CONFIG=release
release: build-impl

# Running: Pipe the parseable output example to the program
.PHONY: run
run: CONFIG=debug
run: build-impl
	cat Examples/parseable-output-example.txt | .build/$(CONFIG)/$(PRODUCT)

.PHONY: run_compile_commands
run_compile_commands: CONFIG=debug
run_compile_commands: build-impl
	.build/$(CONFIG)/$(PRODUCT) compile_commands Examples/parseable-output-example.txt 

.PHONY: clean
clean:
	rm -rf .build/debug/*
	rm -rf .build/release/*

# Build compile_commands.json
# Unfortunately, we need to clean.
# Use the last installed product incase we messed something up during
# coding.
compile_commands.json: SWIFT_OPTS=-Xswiftc -parseable-output
compile_commands.json: CONFIG=debug
compile_commands.json: clean build-impl
	cat $(LAST_LOG) | /usr/local/bin/$(PRODUCT) compile_commands

