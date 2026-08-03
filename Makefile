SHELL_SCRIPTS := script/app_bundle.sh script/build_and_run.sh script/generate_app_icon.sh script/package.sh script/install_latest.sh script/test.sh script/test_install_latest.sh script/validate_app_icon.sh script/version.sh

.PHONY: build check run package install-latest release status

VERSION ?=

build:
	swift build

check:
	./script/test.sh --disable-sandbox
	./script/test_install_latest.sh
	./script/validate_app_icon.sh
	CLANG_MODULE_CACHE_PATH="$(CURDIR)/.build/module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$(CURDIR)/.build/module-cache" swift script/validate_menu_bar_icon.swift Assets/MenuBarTemplate.png
	@for script in $(SHELL_SCRIPTS); do \
		bash -n "$$script"; \
	done

run:
	./script/build_and_run.sh

package:
	SHELFDROP_VERSION="$(VERSION)" ./script/package.sh

install-latest:
	./script/install_latest.sh

release:
	@if [ -z "$(VERSION)" ]; then \
		echo "usage: make release VERSION=v0.1.7" >&2; \
		exit 2; \
	fi
	@SHELFDROP_VERSION="$(VERSION)" bash script/version.sh >/dev/null
	git tag "$(VERSION)"
	git push origin main
	git push origin "$(VERSION)"

status:
	git status -sb
