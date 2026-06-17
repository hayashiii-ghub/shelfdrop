.PHONY: build check run package install-latest release status

VERSION ?=

build:
	swift build

check:
	swift test
	bash -n script/build_and_run.sh script/package.sh script/install_latest.sh

run:
	./script/build_and_run.sh

package:
	./script/package.sh

install-latest:
	./script/install_latest.sh

release:
	@if [ -z "$(VERSION)" ]; then \
		echo "usage: make release VERSION=v0.1.4" >&2; \
		exit 2; \
	fi
	git tag "$(VERSION)"
	git push origin main
	git push origin "$(VERSION)"

status:
	git status -sb
