.PHONY: lint

ACTIONLINT := go run github.com/rhysd/actionlint/cmd/actionlint@v1.7.7

# actionlint runs from the repo root: GitHub only reads workflows from .github/workflows/.
lint:
	cd .. && $(ACTIONLINT) .github/workflows/*.yml ci-cd/examples/*.yml
