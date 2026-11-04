# Shared Backend CI/CD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A public `rusuh-infra` repo with two reusable GitHub Actions workflows (CI and CD) that backend repos call with their own commands, switchable per stage by org variables with per-repo overrides, and `rusuh-queue` moved onto it.

**Architecture:** `backend-ci.yml` runs checks and builds/pushes the image to GHCR on `main`; on a `v*` tag it only verifies the image for that commit exists. `backend-cd.yml` copies that image to ECR and deploys it to ECS (k3s is a failing placeholder). Every stage reads an `on`/`off` switch from `vars` (repo value beats org value, GitHub-native). Self-test workflows in `rusuh-infra` call both workflows against tiny Go and Node fixtures.

**Tech Stack:** GitHub Actions reusable workflows (`workflow_call`), bash, docker buildx, crane, aws-actions (OIDC, ECR login, ECS render/deploy), actionlint.

**Spec:** `rusuh-infra/docs/superpowers/specs/2026-11-04-shared-ci-cd-design.md`

## Global Constraints

- No comments in workflows, scripts or fixtures unless the implementation is ambiguous without one.
- `rusuh-infra` is public: no secrets, no Terraform state, no AWS account IDs or ARNs in the repo.
- Switch values are exactly `on` or `off`; anything else fails the run. Unset = default: `CI_LINT`, `CI_TEST`, `CI_VULN`, `CI_IMAGE` on; `CD_ECS`, `CD_K3S` off.
- Image: `ghcr.io/pt-meeting-sampai-malam-konsultasi/<service>:<full commit sha>`, platforms `linux/amd64,linux/arm64`. PRs build but never push; `main` pushes; tags never build.
- No long-lived AWS keys: OIDC role from `AWS_ROLE_ARN` only.
- CD concurrency group `cd-<service>-<environment>`, `cancel-in-progress: false`.
- Callers pin `@v1` (moving major tag on `rusuh-infra`).
- Commits: `[<issue-code>] | david | <message>`, `INIT` for `rusuh-infra`'s first commit; no AI attribution; no force push; push with `git -c credential.helper= -c credential.helper='!gh auth git-credential' push https://github.com/PT-Meeting-Sampai-Malam-Konsultasi/<repo>.git <branch>`.
- In `rusuh-queue`: never commit `cmd/fakecore`, the `Makefile` local tweak, `api/.apidog`, or `docs/`.
- Do not touch `rusuh-core`.
- Every GitHub-side action (create repo, push, tag, org/repo variables, environments, branch protection, PR) needs David's OK at that moment.
- Lint every workflow with `go run github.com/rhysd/actionlint/cmd/actionlint@v1.7.7` (Go via `source ~/.gvm/scripts/gvm`).

## Review Focus

1. A switch set to `On`, `true`, `1` or with a trailing space must fail the run with the variable name in the error, not silently skip a stage. Task 2 adds a manual-only self-test job with `CI_LINT` forced to `yes` via `switch-overrides`; Task 5 checks it fails.
2. A command input left empty must show "not configured" in the summary and not fail. Task 2's Node fixture leaves `vuln` and `extra` empty.
3. A tag on a commit not on `main`, or whose GHCR image does not exist yet, must fail `verify-release` with a message saying which. Task 2 verification covers the missing-image case on the self-test tag run.
4. `CD_ECS=on` with any AWS variable missing must fail before touching AWS, naming the missing variables. Task 3 adds a `check-config` step and a manual-only self-test with `CD_ECS=on` and no AWS variables; Task 5 checks it fails.
5. A PR from a fork must never push an image or reach AWS. Task 2's push condition is `github.event_name == 'push' && github.ref == 'refs/heads/main'`; Task 3's deploy only runs from the tag flow; Task 5 verifies the PR run shows the image job built without pushing.

---

### Task 1: Bootstrap the local `rusuh-infra` repo

**Files:**
- Create: `rusuh-infra/README.md`, `rusuh-infra/.gitignore`, `rusuh-infra/Makefile`
- Existing: `rusuh-infra/docs/superpowers/specs/2026-11-04-shared-ci-cd-design.md`, this plan

**Interfaces:**
- Produces: `make lint` in `rusuh-infra` runs actionlint over `.github/workflows/`.

- [ ] **Step 1:** `git init -b main` in `rusuh-infra`.
- [ ] **Step 2:** `.gitignore`: `*.tfstate`, `*.tfstate.*`, `.terraform/`, `*.tfvars`, `.env`.
- [ ] **Step 3:** `Makefile` target `lint`: `go run github.com/rhysd/actionlint/cmd/actionlint@v1.7.7 .github/workflows/*.yml $(wildcard examples/*.yml)`.
- [ ] **Step 4:** `README.md`: one paragraph on what the repo is, links to `docs/ci-cd.md` (Task 4) and the spec.
- [ ] **Step 5:** Commit `[INIT] | david | start rusuh-infra with the shared CI/CD design`.

### Task 2: Reusable CI workflow + self-test

**Files:**
- Create: `.github/workflows/backend-ci.yml`
- Create: `.github/workflows/self-test.yml`
- Create: `tests/fixtures/go-app/{go.mod,main.go,main_test.go,Dockerfile}`
- Create: `tests/fixtures/node-app/{package.json,package-lock.json,.nvmrc,index.js,index.test.js,Dockerfile}`

**Interfaces:**
- Produces `backend-ci.yml` `on: workflow_call` with inputs (all `type: string`):
  `service` (required), `runtime` (required, `go`|`node`), `runtime-version-file` (required),
  `working-directory` (default `.`), `setup`, `format`, `lint`, `vuln`, `test`, `extra` (default `''`),
  `platforms` (default `linux/amd64,linux/arm64`), `switch-overrides` (default `''`, JSON object used only by self-test, e.g. `{"CI_LINT":"yes"}`).
- Jobs and their ids (status check names are `<caller job id> / <job id>`): `switches`, `checks`, `image`, `verify-release`.
- `switches` outputs: `lint`, `test`, `vuln`, `image` each `on`|`off`.
- Workflow output `image`: full GHCR ref with sha.
- Caller must grant `contents: read`, `packages: write`.

- [ ] **Step 1: Write fixtures.** Go app: `go 1.27` module `example.com/go-app`, `Add(a, b int) int` with `TestAdd` asserting `Add(2, 3) == 5`, distroless Dockerfile like `rusuh-queue/Dockerfile`. Node app: `package.json` scripts `lint` = `node --check index.js`, `test` = `node --test`, `.nvmrc` = `22`, `index.js` exporting `add`, `index.test.js` asserting `add(2, 3) === 5`, Dockerfile on `node:22-alpine`; generate `package-lock.json` with `npm install` (no dependencies) so `setup-node`'s npm cache has a lock file.

- [ ] **Step 2: Write `self-test.yml`** (triggers: `pull_request`, `push` to `main`, `push` tags `v*`, `workflow_dispatch` with boolean input `negative`, default false) calling `./.github/workflows/backend-ci.yml`:
  - `go`: service `rusuh-ci-fixture-go`, runtime `go`, `runtime-version-file: tests/fixtures/go-app/go.mod`, working-directory `tests/fixtures/go-app`, format `test -z "$(gofmt -l .)"`, lint `go vet ./...`, vuln `go run golang.org/x/vuln/cmd/govulncheck@latest ./...`, test `go test -race ./...`, extra `go build ./...`.
  - `node`: service `rusuh-ci-fixture-node`, runtime `node`, `runtime-version-file: tests/fixtures/node-app/.nvmrc`, working-directory `tests/fixtures/node-app`, setup `npm ci`, lint `npm run lint`, test `npm test`; `format`, `vuln`, `extra` empty.
  - `bad-switch`: `if: inputs.negative`, same as `go` with `switch-overrides: '{"CI_LINT":"yes"}'`. Expected to fail; it runs only on a manual dispatch so normal runs stay green.

- [ ] **Step 3: Run lint, expect failure.** `make lint` → FAIL (`backend-ci.yml` not found).

- [ ] **Step 4: Implement `backend-ci.yml`.**
  - `switches` job: one bash step with env `CI_LINT: ${{ vars.CI_LINT }}` etc. and `OVERRIDES: ${{ inputs.switch-overrides }}`. For each name: value = override (via `jq -r --arg k NAME '.[$k] // empty'`) else var else default; if not exactly `on`/`off` → `::error::` with name and value, exit 1. Write outputs and a `$GITHUB_STEP_SUMMARY` table: Stage | Switch | Value, plus a row per command input: configured / not configured.
  - `checks`: `needs: switches`, `if: github.ref_type != 'tag'`, `defaults.run.working-directory: inputs.working-directory`. Checkout; `actions/setup-go@v5` with `go-version-file` when runtime `go`, `actions/setup-node@v4` with `node-version-file` and `cache: npm` + `cache-dependency-path: <wd>/package*.json` when `node`; unknown runtime → error. Steps `setup`, `format` + `lint` (switch `lint`), `vuln` (switch `vuln`), `test` (switch `test`), `extra`; each `if:` its switch and `inputs.<x> != ''`; run with `bash -eo pipefail -c "$CMD"` via env `CMD`.
  - `image`: `needs: [switches, checks]`, `if: github.ref_type != 'tag' && needs.switches.outputs.image == 'on'`. Compute `IMAGE=ghcr.io/${GITHUB_REPOSITORY_OWNER,,}/<service>:${GITHUB_SHA}`. qemu, buildx, GHCR login only when pushing, `docker/build-push-action@v6` with context `inputs.working-directory`, `platforms`, `push` = `github.event_name == 'push' && github.ref == 'refs/heads/main'`, GHA cache scoped by `inputs.service`.
  - `verify-release`: `needs: switches`, `if: github.ref_type == 'tag'`. Checkout with `fetch-depth: 0`; `git merge-base --is-ancestor "$GITHUB_SHA" origin/main` else `::error::tag <tag> points at <sha>, which is not on main`; GHCR login with `GITHUB_TOKEN`; `docker buildx imagetools inspect "$IMAGE"` else `::error::image <ref> not found; wait for main CI on this commit to finish, then re-run`.
  - Workflow output `image` from the `switches` job (compute the ref there).

- [ ] **Step 5: Lint passes.** `make lint` → no output, exit 0.

- [ ] **Step 6: Commit** `[INIT] | david | add the reusable backend CI workflow with Go and Node self-tests`. (Live runs happen in Task 5.)

### Task 3: Reusable CD workflow + self-test

**Files:**
- Create: `.github/workflows/backend-cd.yml`
- Modify: `.github/workflows/self-test.yml`

**Interfaces:**
- Consumes: the GHCR ref convention from Task 2.
- Produces `backend-cd.yml` `on: workflow_call` with inputs `service` (required), `environment` (default `production`), `switch-overrides` (default `''`).
- Jobs: `switches` (outputs `ecs`, `k3s`, `image`, `release`), `promote-ecr`, `deploy-ecs`, `deploy-k3s`, `summary`.
- Caller must grant `contents: read`, `packages: read`, `id-token: write`.

- [ ] **Step 1: Self-test entries.** In `self-test.yml` add `cd-dry-run` (`if: github.ref_type == 'tag'`, `needs: go`) calling `./.github/workflows/backend-cd.yml` with service `rusuh-ci-fixture-go`, no overrides; and `cd-missing-config` (`if: inputs.negative`) with `switch-overrides: '{"CD_ECS":"on"}'` and `environment: self-test` (an environment with no variables). The `switches` job's tag-only rule is skipped when `switch-overrides` is non-empty so this can run from a manual dispatch.

- [ ] **Step 2: Run lint, expect failure.** `make lint` → FAIL (`backend-cd.yml` not found).

- [ ] **Step 3: Implement `backend-cd.yml`.**
  - Top-level `concurrency: { group: cd-${{ inputs.service }}-${{ inputs.environment }}, cancel-in-progress: false }`.
  - `switches`: same resolution as CI for `CD_ECS`, `CD_K3S` (defaults off); outputs the GHCR ref and `release = github.ref_name`; fails unless `github.ref_type == 'tag'`.
  - `promote-ecr`: `if: ecs == 'on'`, `environment: inputs.environment`. Step `check-config`: fail with `::error::missing variables: <list>` if any of `AWS_REGION`, `AWS_ROLE_ARN`, `ECR_REGISTRY`, `ECS_CLUSTER`, `ECS_SERVICE`, `ECS_TASK_FAMILY` is empty. Then `aws-actions/configure-aws-credentials@v4` (role, region), `aws-actions/amazon-ecr-login@v2`, GHCR login, `imjasonh/setup-crane@v0.4`, `crane copy <ghcr ref> $ECR_REGISTRY/<service>:<sha>`, `crane tag $ECR_REGISTRY/<service>:<sha> <release>`. Output `ecr-image`.
  - `deploy-ecs`: `needs: [switches, promote-ecr]`, same environment. Configure credentials; `aws ecs describe-task-definition --task-definition "$ECS_TASK_FAMILY" --query taskDefinition > task-def.json`; `aws-actions/amazon-ecs-render-task-definition@v1` with `container-name: ${{ vars.ECS_CONTAINER || inputs.service }}` and the ECR image; `aws-actions/amazon-ecs-deploy-task-definition@v2` with `service`, `cluster`, `wait-for-service-stability: true`. If the deploy action rejects read-only fields from `describe-task-definition`, strip them with `jq 'del(.taskDefinitionArn,.revision,.status,.requiresAttributes,.compatibilities,.registeredAt,.registeredBy)'`.
  - `deploy-k3s`: `if: k3s == 'on'`; `::error::k3s deploy is not implemented yet; set CD_K3S=off`, exit 1.
  - `summary`: `needs: [switches, promote-ecr, deploy-ecs, deploy-k3s]`, `if: always()`; table: service, release, sha, GHCR image, environment, ECS on/off + result, k3s on/off + result; when both off, heading "Dry run: nothing deployed".

- [ ] **Step 4: Lint passes.** `make lint` → exit 0.

- [ ] **Step 5: Commit** `[INIT] | david | add the reusable backend CD workflow (ECR promote, ECS deploy, k3s placeholder)`.

### Task 4: Docs and starter callers

**Files:**
- Create: `docs/ci-cd.md`, `examples/go-caller.yml`, `examples/node-caller.yml`

**Interfaces:**
- Consumes: input names and job ids from Tasks 2–3.

- [ ] **Step 1: `examples/go-caller.yml`.** Triggers `pull_request`, push `main`, push tags `v*`. Job `ci` → `backend-ci.yml@v1` with `rusuh-queue`'s commands (format `make fmt-check`, lint `go vet ./... && make lint`, vuln `make vuln`, test `go test -race ./...`, extra = sqlc generate + `git diff --exit-code -- internal/` guarded by `test -f sqlc.yaml`), permissions `contents: read, packages: write`. Job `cd` → `backend-cd.yml@v1`, `needs: ci`, `if: github.ref_type == 'tag'`, permissions `contents: read, packages: read, id-token: write`.
- [ ] **Step 2: `examples/node-caller.yml`.** Same shape, runtime `node`, `runtime-version-file: .nvmrc`, setup `npm ci`, lint `npm run lint`, test `npm test`, vuln `npm audit --audit-level=high`, format/extra empty.
- [ ] **Step 3: `docs/ci-cd.md`.** Sections: how to plug in (copy an example, set `service`); inputs table; switches table (name, default, stage) and how override works (org variable vs same-name repo variable, delete to fall back); CD variables table (from the spec, plus `ECS_CONTAINER`) and where each is set; Terraform contract (Terraform owns cluster/service/IAM/first task def, `ignore_changes = [task_definition]` on the service, CD owns later images); release checklist: 1 merge to `main`, 2 wait for green `main` CI, 3 apply migrations manually if the release needs them, 4 push tag `vX.Y.Z`; required status checks (filled in Task 5); how to release `rusuh-infra` itself (tag `v1.x.y`, move `v1`).
- [ ] **Step 4:** `make lint` (examples are linted too: add `examples/*.yml` to the actionlint call) → exit 0.
- [ ] **Step 5: Commit** `[INIT] | david | document the shared pipeline and add Go and Node starter callers`.

### Task 5: Publish `rusuh-infra` and prove it live (needs David's OK at each step)

- [ ] **Step 1:** Ask David; then `gh repo create PT-Meeting-Sampai-Malam-Konsultasi/rusuh-infra --public` and push `main`.
- [ ] **Step 2:** Ask David; create environment `self-test` (no variables) and `production` in `rusuh-infra`. Org variables: `CI_LINT=on`, `CI_TEST=on`, `CI_VULN=on`, `CI_IMAGE=on`, `CD_ECS=off`, `CD_K3S=off`.
- [ ] **Step 3: Verify the push run.** `gh run watch` on the `main` self-test run. Expected: run green; switches summary lists every switch `on` and Node `vuln`/`extra` as "not configured"; fixture images pushed to GHCR.
- [ ] **Step 4: Verify the negative cases.** `gh workflow run self-test.yml -f negative=true`. Expected: `bad-switch` fails with `CI_LINT` and `yes` in the error; `cd-missing-config` fails listing all six AWS variables; `go` and `node` green.
- [ ] **Step 5:** Tag `v1.0.0` and `v1` on the `main` commit, push tags. Expected tag run: `verify-release` green for both fixtures; `cd-dry-run` summary says "Dry run: nothing deployed".
- [ ] **Step 6: Verify the not-on-main path.** With OK, push a scratch branch with one commit and a tag `v0.0.0-check` on it. Expected: `verify-release` fails with the "not on main" message. Delete the tag and branch afterwards (with OK).
- [ ] **Step 7:** If any step fails, fix in a new commit, re-tag `v1.0.1` and move `v1` (moving `v1` is a tag update; ask David first since it rewrites a pushed tag).

### Task 6: Move `rusuh-queue` onto the shared pipeline

**Files:**
- Modify: `rusuh-queue/.github/workflows/ci.yml` (replace wholly with `examples/go-caller.yml` content)

- [ ] **Step 1:** From `main` in `rusuh-queue`, create branch `ci/shared-pipeline`. Leave `Makefile`, `docs/`, `cmd/fakecore`, `api/.apidog` untouched.
- [ ] **Step 2:** Replace `ci.yml` with the Go caller. `go run github.com/rhysd/actionlint/cmd/actionlint@v1.7.7 .github/workflows/ci.yml` → exit 0.
- [ ] **Step 3:** Ask David for the issue code, commit `[<code>] | david | run CI on the shared rusuh-infra pipeline`, push (with OK), open PR (with OK).
- [ ] **Step 4: Verify on the PR.** Expected: `ci / switches`, `ci / checks` green (same steps as the old `ci.yml`, sqlc drift under `extra`), `ci / image` built and not pushed; no `cd` job.
- [ ] **Step 5: Verify override.** With OK, set repo variable `CI_VULN=off` on `rusuh-queue`, re-run: summary shows `CI_VULN off`, vuln step skipped. Delete the repo variable, re-run: back to `on`.
- [ ] **Step 6:** Record the required check names (`ci / checks`, `ci / image`) in `rusuh-infra/docs/ci-cd.md`, commit `[INIT] | david | record required status checks`, push. With OK, set them as required in `rusuh-queue` branch protection for `main`.
- [ ] **Step 7:** Capture in ngotak daily note: one line on what shipped and the check names.
