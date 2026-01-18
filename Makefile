.PHONY: all build test run stop restart bundle install clean help

APP_NAME := LoggerTXT
DEBUG_BIN := .build/debug/$(APP_NAME)
RELEASE_BIN := .build/release/$(APP_NAME)
BUNDLE_DIR := .build/release/Logger-TXT.app

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

# Stop the running app
stop:
	@echo "Stopping $(APP_NAME)..."
	@-pkill -x $(APP_NAME) 2>/dev/null || echo "$(APP_NAME) is not running"

# Restart the app
restart: stop
	@sleep 0.5
	@$(MAKE) run

# Create .app bundle
bundle:
	@./Scripts/bundle.sh

# Install to /Applications
install: bundle
	@echo "Installing to /Applications..."
	@cp -r "$(BUNDLE_DIR)" /Applications/
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
	@echo "  make stop     - Stop the running app"
	@echo "  make restart  - Stop and restart the app"
	@echo "  make bundle   - Create .app bundle for distribution"
	@echo "  make install  - Bundle and install to /Applications"
	@echo "  make clean    - Remove build artifacts"
	@echo "  make help     - Show this help"
