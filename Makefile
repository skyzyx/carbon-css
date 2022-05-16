#-------------------------------------------------------------------------------
# Running `make` will show the list of subcommands that will run.

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(dir $(mkfile_path))

#-------------------------------------------------------------------------------
# Global stuff.

GO=$(shell which go)
BREW_PREFIX=$(shell brew --prefix)

# Determine which version of `echo` to use. Use version from coreutils if available.
ECHOCHECK := $(shell command -v $(BREW_PREFIX)/opt/coreutils/libexec/gnubin/echo 2> /dev/null)
ifdef ECHOCHECK
    ECHO="$(BREW_PREFIX)/opt/coreutils/libexec/gnubin/echo" -e
else
    ECHO=echo
endif

#-------------------------------------------------------------------------------
# Running `make` will show the list of subcommands that will run.

all: help

.PHONY: help
## help: [help]* Prints this help message.
help:
	@ $(ECHO) "Usage:"
	@ $(ECHO) ""
	@ sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /' | \
		while IFS= read -r line; do \
			if [[ "$$line" == *"]*"* ]]; then \
				$(ECHO) "\033[1;33m$$line\033[0m"; \
			else \
				$(ECHO) "$$line"; \
			fi; \
		done

#-------------------------------------------------------------------------------
# Clean

.PHONY: clean-dist
## clean-dist: [clean] Removes the `dist` directory.
clean-dist:
	@ echo " "
	@ echo "=====> Cleaning the dist directory..."
	- rm -Rf ./dist

.PHONY: clean
## clean: [clean]* Runs ALL cleaning tasks.
clean: clean-dist

#-------------------------------------------------------------------------------
# Build

.PHONY: build
## build: [build] Builds a compiled version of the source distribution.
build:
	@ echo " "
	@ echo "=====> Updating the README..."
	- npm run compile

#-------------------------------------------------------------------------------
# Linting

.PHONY: markdownlint
## markdownlint: [lint] Runs `markdownlint` (formatting, spelling) against all Markdown.
markdownlint:
	@ echo " "
	@ echo "=====> Running Markdownlint..."
	- npm run markdownlint

.PHONY: eslint
## eslint: [lint] Runs `eslint` (formatting, static analysis) against all JavaScript.
eslint:
	@ echo " "
	@ echo "=====> Running eslint..."
	- npm run lint

.PHONY: lint
## lint: [lint]* Runs ALL linting/validation tasks.
lint: markdownlint eslint

#-------------------------------------------------------------------------------
# Git Tasks

.PHONY: tag
## tag: [release]* tags (and GPG-signs) the release
tag:
	@ if [ $$(git status -s -uall | wc -l) != 1 ]; then echo 'ERROR: Git workspace must be clean.'; exit 1; fi;

	@echo "This release will be tagged as: $(shell jq -r '.version' package.json)"
	@echo "This version should match your release. If it doesn't, re-run 'make version'."
	@echo "---------------------------------------------------------------------"
	@read -p "Press any key to continue, or press Control+C to cancel. " x;

	@echo " "
	@chag update $(shell jq -r '.version' package.json)
	@echo " "

	@echo "These are the contents of the CHANGELOG for this release. Are these correct?"
	@echo "---------------------------------------------------------------------"
	@chag contents
	@echo "---------------------------------------------------------------------"
	@echo "Are these release notes correct? If not, cancel and update CHANGELOG.md."
	@read -p "Press any key to continue, or press Control+C to cancel. " x;

	@echo " "

	git add .
	git commit -a -m "Preparing the $(shell jq -r '.version' package.json) release."
	chag tag --sign

.PHONY: version
## version: [release]* sets the version for the next release; pre-req for a release tag
version:
	@echo "Current version: $(shell jq -r '.version' package.json)"
	@read -p "Enter new version number: " nv && \
		npm version --allow-same-version --no-commit-hooks --no-git-tag-version "$$nv";

.PHONY: publish
## publish: [release]* publishes the package to npm
publish:
	npm publish --otp $(shell op item get g43gnmoyibgzdc334gbbzumhky --fields type=otp --format json | jq -Mr '.totp')
