.PHONY: lint

ACTIONLINT := go run github.com/rhysd/actionlint/cmd/actionlint@v1.7.7

lint:
	$(ACTIONLINT) .github/workflows/*.yml $(wildcard examples/*.yml)
