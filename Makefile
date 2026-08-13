.PHONY: all build test run run-scratch stop restart bundle verify-bundle install clean help

APP_NAME := LoggerTXT
DEBUG_BIN := .build/debug/$(APP_NAME)
RELEASE_BIN := .build/release/$(APP_NAME)
BUNDLE_DIR := .build/release/Logger-TXT.app

# Scratch log for development runs. `make run` reads whatever logFilePath is
# saved in preferences, which is a real log file — use run-scratch to point the
# app at a throwaway file instead.
SCRATCH_LOG := $(TMPDIR)logger-txt-dev.txt

# Default target
all: build

# Build debug version
build:
	@echo "Building $(APP_NAME) (debug)..."
	@swift build
	@echo "Build complete: $(DEBUG_BIN)"

# Build release version
release:
	@echo "Building $(APP_NAME) (release)..."
	@swift build -c release
	@echo "Build complete: $(RELEASE_BIN)"

# Run tests
test:
	@echo "Running tests..."
	@swift test

# Run the app (builds first if needed)
run: build
	@echo "Starting $(APP_NAME)..."
	@$(DEBUG_BIN) &

# Run against a throwaway log file, leaving the real one alone. The -logFilePath
# argument lands in NSArgumentDomain, which outranks the saved preference and is
# never written back to disk.
run-scratch: build
	@touch "$(SCRATCH_LOG)"
	@echo "Starting $(APP_NAME) against $(SCRATCH_LOG)..."
	@$(DEBUG_BIN) -logFilePath "$(SCRATCH_LOG)" &

# Stop the running app
stop:
	@echo "Stopping $(APP_NAME)..."
	@-pkill -x $(APP_NAME) 2>/dev/null || echo "$(APP_NAME) is not running"

# Restart the app
restart: stop
	@sleep 0.5
	@$(MAKE) run

# Create .app bundle (self-verifies its resource bundles)
bundle:
	@./Scripts/bundle.sh

# Verify an already-built bundle without rebuilding
verify-bundle:
	@./Scripts/verify-app-bundle.sh "$(BUNDLE_DIR)"

# Install to /Applications. Replaces rather than merges: `cp -r` over an
# existing .app leaves stale files from the previous install behind, and ditto
# preserves the resource-bundle symlink at the app root.
install: bundle
	@echo "Installing to /Applications..."
	@rm -rf /Applications/Logger-TXT.app
	@ditto "$(BUNDLE_DIR)" /Applications/Logger-TXT.app
	@echo "Installed Logger-TXT.app to /Applications"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@swift package clean
	@rm -rf .build
	@echo "Clean complete"

# Show help
help:
	@echo "Logger-TXT Development Commands"
	@echo ""
	@echo "  make build    - Build debug version"
	@echo "  make release  - Build release version"
	@echo "  make test     - Run tests"
	@echo "  make run      - Build and run the app"
	@echo "  make run-scratch  - Run against a throwaway log file"
	@echo "  make stop     - Stop the running app"
	@echo "  make restart  - Stop and restart the app"
	@echo "  make bundle   - Create .app bundle for distribution"
	@echo "  make verify-bundle - Check the built .app carries its resource bundles"
	@echo "  make install  - Bundle and install to /Applications"
	@echo "  make clean    - Remove build artifacts"
	@echo "  make help     - Show this help"
