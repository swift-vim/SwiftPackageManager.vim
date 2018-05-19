.PHONY: run
run:
	swift build
	./.build/debug/SPMVim log
