.PHONY: build check run package install-latest release status

VERSION ?=

build:
	swift build

check:
	./script/test.sh
	./script/test_install_latest.sh
	bash -n script/build_and_run.sh script/package.sh script/install_latest.sh script/test.sh script/test_install_latest.sh script/version.sh

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
