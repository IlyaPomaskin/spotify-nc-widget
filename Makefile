TEAM_ID ?= ABDSR7WU8G
XCODEGEN ?= xcodegen
APP_NAME := SpotifyWidget.app
PRODUCT := build/Build/Products/Release/$(APP_NAME)
INSTALL_DIR := $(HOME)/Applications
LSREGISTER := /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
SANDBOX_FLAGS := -IDEPackageSupportDisableManifestSandbox=YES -IDEPackageSupportDisablePluginExecutionSandbox=YES

.PHONY: gen test check build install

gen:
	TEAM_ID=$(TEAM_ID) $(XCODEGEN) generate

test:
	cd NowPlayingKit && swift test --disable-sandbox

check: gen
	xcodebuild -project SpotifyWidget.xcodeproj -scheme SpotifyWidget -configuration Release \
		-derivedDataPath build $(SANDBOX_FLAGS) CODE_SIGNING_ALLOWED=NO build -quiet

build: gen
	@test -n "$(TEAM_ID)" || (echo "TEAM_ID is required: make build TEAM_ID=XXXXXXXXXX" && exit 1)
	xcodebuild -project SpotifyWidget.xcodeproj -scheme SpotifyWidget -configuration Release \
		-derivedDataPath build $(SANDBOX_FLAGS) -allowProvisioningUpdates build -quiet

install: build
	pkill -x SpotifyWidget || true
	rm -rf "$(INSTALL_DIR)/$(APP_NAME)"
	mkdir -p "$(INSTALL_DIR)"
	cp -R "$(PRODUCT)" "$(INSTALL_DIR)/"
	$(LSREGISTER) -f -R "$(INSTALL_DIR)/$(APP_NAME)"
	$(LSREGISTER) -u "$(PRODUCT)"
	open "$(INSTALL_DIR)/$(APP_NAME)"
