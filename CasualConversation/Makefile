SWIFTLINT_PATH := $(shell which swiftlint)

install:
	@make close_xcode
	@echo "\033[34m[1/5] Running 'tuist clean'...\033[39m"
	@make clean
	@echo "\033[34m[2/5] Running 'tuist install'...\033[39m"
	@make tuist_install
#	@echo "\033[34m[3/6] Running 'tuist cache'...\033[39m"
#	@make cache
	@echo "\033[34m[3/5] Running 'tuist generate'...\033[39m"
	@make generate
#	@echo "\033[34m[4/6] Running 'pod_install'...\033[39m"
#	@make pod_install
	@echo "\033[34m[4/5] Running 'tuist graph'...\033[39m"
	@make depency_graph
	@echo "\033[34m[5/5] Running 'open Xcode'...\033[39m"
	@make open_xcode
	@echo "\033[32mCompleted!\033[39m"

clean:
	@tuist clean

edit:
	@tuist edit

tuist_install:
	@tuist install
	
cache:
	@tuist cache

depency_graph:
	tuist graph -t

generate:
	@TUIST_ROOT_DIR=$(SWIFTLINT_PATH) tuist generate --no-open

pod_install:
	@pod install --repo-update
	
open_xcode:
	@open CCRecorderApp.xcworkspace
	
close_xcode:
	-@pkill -x Xcode
