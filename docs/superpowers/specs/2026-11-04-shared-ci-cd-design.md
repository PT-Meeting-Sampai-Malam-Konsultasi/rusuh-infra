# Shared CI/CD for the Rusuh backends: design

Date: 4 Nov 2026. Author: David (Backend 1). Status: draft for approval.

## Intent

Rusuh has two backend services in GitHub org `PT-Meeting-Sampai-Malam-Konsultasi`:

| Repo | Stack | Owner | CI today |
| --- | --- | --- | --- |
| `rusuh-queue` | Go 1.27 | Backend 1 | `.github/workflows/ci.yml` (own copy) |
| `rusuh-core` | Node.js | Backend 2 | none yet; skeleton in progress, untouched by this work |

We want **one pipeline, defined once, used by both**. Each repo keeps only a thin file that
says *its* commands (how to set up, lint, test, scan). Stage order, rules, image build,
image promotion and deployment live in the shared part. Improving the pipeline once
improves both repos, and Backend 2 does not build a pipeline from scratch.

The pipeline will grow: Sonar, SAST, DAST and similar stages are expected later. Each stage
must be switchable on/off **centrally**, and each repo may **override** a switch for itself.

## Goals

1. A shared CI pipeline in a new org repo **`rusuh-infra`**, used by both backend repos.
2. Per-repo details (runtime, commands, extra checks) passed in from each repo's thin caller file.
3. Every optional stage has an on/off switch: org default, repo override.
4. CD runs **only on a release tag**, deploys the image CI already built (no rebuild), to
   **ECS** now, with **k3s** as a second target later. Targets are switched independently and can both be on.
5. Environment is a parameter. Only `production` exists now; more (e.g. `staging`) can be added later
   without a new pipeline.
6. `rusuh-queue` is moved onto the shared pipeline as the first user and proof. The Node
   starter caller (`examples/node-caller.yml`) is written for later; `rusuh-core` itself is not
   touched until Backend 2 finishes its skeleton.

## Non-goals

- Creating AWS resources (ECR repos, ECS cluster/services, IAM/OIDC role). That is the later
  Terraform part of `rusuh-infra`.
- Writing the k3s deploy job. Only a switch and a placeholder job now.
- Writing the Sonar/SAST/DAST stages. The design only has to make adding them easy.
- Frontend repos (`rusuh-web`, `rusuh-app`).
- Staging, approvals, rollback automation.
- **Database migrations in CD.** Migrations (goose, `db/migrations` in rusuh-queue) are run
  **manually** before a release that needs them. CD does not run them. `docs/ci-cd.md` must say
  so in the release checklist: "apply migrations first, then tag".
- Any change to `rusuh-core` (repo, Dockerfile, workflows) in this work.

## Anti-goals (would be a failure even if it works)

- Copy-pasting pipeline logic into each repo again.
- A deployed image that differs from the one CI tested (no rebuild on release).
- Long-lived AWS keys stored in GitHub secrets.
- A stage silently skipped with no visible reason.
- Pull requests from anyone being able to push images or reach AWS.

## Decisions (made by David)

- Shared repo name: **`rusuh-infra`**. It will hold CI/CD now and Terraform later.
- Switches: central default, **each repo can override for itself**.
- CD trigger: **release tag only**.
- CD targets: **ECS now**, k3s later; both can run, each by its own switch.
- Environments: **production only** now; others later.
- Registry for ECS: **ECR**.
- AWS is not set up yet; it will come from Terraform.
- This document is the first file of `rusuh-infra`.
- `rusuh-infra` is **public** (public backend repos cannot call workflows in a private repo).
  So: no secrets, no Terraform state, no account-specific values in the repo; those live in
  GitHub variables/secrets and a remote state backend.
- Migrations stay **manual** for now.
- `rusuh-core` stays untouched until Backend 2 finishes its skeleton.

## How it works

### Repo layout (`rusuh-infra`)

GitHub only runs shared (reusable) workflows from `.github/workflows/`, so:

```
rusuh-infra/
  .github/workflows/
    backend-ci.yml        # reusable: checks + image build/push to GHCR
    backend-cd.yml        # reusable: promote to ECR + deploy targets
  docs/
    superpowers/specs/    # this document
    ci-cd.md              # how a repo plugs in; table of switches and variables
  examples/
    go-caller.yml         # starter caller for a Go service (rusuh-queue)
    node-caller.yml       # starter caller for a Node service (rusuh-core)
  terraform/              # later
```

`rusuh-infra` is public, so no access setting is needed for callers.

Callers pin the shared workflow to a ref. Builder's call: tag `rusuh-infra` releases
(`v1`, moving major tag) and callers use `@v1`, so a broken change on `main` does not break
both repos at once.

### Caller file (in each backend repo)

`.github/workflows/ci.yml` in each backend repo, roughly:

```yaml
on:
  pull_request:
  push:
    branches: [main]
    tags: ['v*']
jobs:
  ci:
    uses: PT-Meeting-Sampai-Malam-Konsultasi/rusuh-infra/.github/workflows/backend-ci.yml@v1
    with:
      service: rusuh-queue
      runtime: go                 # go | node
      runtime-version-file: go.mod   # or .nvmrc / package.json
      setup: ''                   # e.g. "npm ci"
      format: make fmt-check
      lint: make lint
      test: go test -race ./...
      vuln: make vuln             # e.g. "npm audit --audit-level=high"
      extra: |                    # repo-only checks, e.g. sqlc drift
        go run github.com/sqlc-dev/sqlc/cmd/sqlc@v1.30.0 generate
        git diff --exit-code -- internal/
    secrets: inherit
  cd:
    if: startsWith(github.ref, 'refs/tags/v')
    needs: ci
    uses: PT-Meeting-Sampai-Malam-Konsultasi/rusuh-infra/.github/workflows/backend-cd.yml@v1
    with:
      service: rusuh-queue
      environment: production
    secrets: inherit
```

Empty command input = that step is skipped and the summary says "not configured".
Input names above are a sketch; the builder may refine them but keep the shape
(runtime + one input per stage + `extra`).

### Switches

Each switch is a GitHub Actions **variable** with the same name at two levels:

- **Org variable** = central default (e.g. `CI_SONAR=off`).
- **Repo variable** with the same name = override for that repo. GitHub gives the repo value
  priority automatically. Deleting it returns the repo to the org default.

Flipping a switch is a settings change: no commit, no PR. Values are `on` / `off`; anything
else fails the run with a clear message (builder's call, avoids typos silently disabling a stage).

Switches now:

| Variable | Default (org) | Stage |
| --- | --- | --- |
| `CI_LINT` | on | format + lint |
| `CI_TEST` | on | tests |
| `CI_VULN` | on | dependency vulnerability scan |
| `CI_IMAGE` | on | build image (push only on `main`/tags) |
| `CD_ECS` | **off** until Terraform exists | promote to ECR + deploy to ECS |
| `CD_K3S` | off | placeholder |

Later stages add a row, e.g. `CI_SONAR`, `CI_SAST`, `CI_DAST`, default off until ready.

Reusable workflows cannot read the caller's `vars` context directly in every place, so the
first job of each shared workflow (**`switches`**) resolves every switch once, exposes them
as job outputs, and writes a table to the run summary: switch, value, and where the value
came from if determinable (otherwise just the value). Later jobs use `if:` on those outputs.
A switched-off stage shows as **skipped**, never failed, and is listed in the summary.
(Builder: verify how `vars` behave inside `workflow_call`; if the caller's repo variables are
not visible, the caller passes `${{ toJSON(vars) }}` or the specific variables as an input.)

### CI (`backend-ci.yml`)

Runs on every PR and on push to `main` and to `v*` tags.

1. `switches`: resolve and print switches.
2. `checks`: checkout, set up runtime (Go via `actions/setup-go` with the version file; Node via
   `actions/setup-node` with cache), run `setup`, then format, lint, vuln, test, `extra`,
   each guarded by its switch and by its input being non-empty. Docker is available on the
   runner (rusuh-queue integration tests use testcontainers).
3. `image`: needs `checks`. Multi-arch build (`linux/amd64,linux/arm64`, as today) with
   buildx and GHA cache. Builds on PRs (to prove it builds) and on `main`; **pushes only on `main`**.
   Image: `ghcr.io/pt-meeting-sampai-malam-konsultasi/<service>:<full commit sha>`.
   **On a `v*` tag CI does not build at all** (David's call: no rebuild on release; builder's call
   on how): the tag run skips `checks` and `image`, and runs a `verify-release` job that fails unless
   (a) the tagged commit is on `main` and (b) `ghcr.io/...:<sha>` already exists. Tagging a commit
   before its `main` CI finished therefore fails with a clear message ("wait for main CI, then
   re-run"). The `main` run never pushes a tag-named image, so the two runs cannot race on a tag.

**Merge gate**: the checks that are switched on. Branch protection on each backend repo
requires the `ci / checks` job (and `ci / image` build). Builder: confirm the exact status
check names after the first run and record them in `docs/ci-cd.md`.

Permissions: `contents: read` by default; `packages: write` only on `image`.

### CD (`backend-cd.yml`)

Runs only for a `v*` tag, after CI passed on that tag's commit.

1. `switches`.
2. `promote-ecr` (if `CD_ECS=on`): log in to AWS via **GitHub OIDC** (`aws-actions/configure-aws-credentials`,
   role from variable), copy the image from GHCR to ECR **without rebuilding**
   (multi-arch manifest copy, e.g. `docker buildx imagetools create` or `crane copy`), tagging it
   `<sha>` and `<release tag>`.
3. `deploy-ecs` (needs `promote-ecr`): download the latest revision of `ECS_TASK_FAMILY` from AWS,
   swap the image of container `ECS_CONTAINER` (default = `service`) to the ECR `<sha>` image,
   register it, update the service, wait for it to be stable (`aws-actions/amazon-ecs-deploy-task-definition`
   with `wait-for-service-stability`). Not stable = run fails.
4. `deploy-k3s` (if `CD_K3S=on`): placeholder that prints "not implemented" and fails, so turning
   it on by mistake is visible. Real job later (pulls from GHCR).
5. When every target is off, a `summary` step writes what *would* be deployed (service, tag,
   sha, image, targets), so the tag flow is testable before AWS exists.

The deploy jobs run in the GitHub **Environment** named by `environment` (`production`).
Environment-scoped variables hold the AWS details, so a later `staging` is a new Environment
with its own values plus approvers if wanted.

Variables needed (names are a proposal; the builder may rename and must document them):

| Variable | Level | Example |
| --- | --- | --- |
| `AWS_REGION` | org or environment | `ap-southeast-3` (Jakarta) |
| `AWS_ROLE_ARN` | environment | role GitHub assumes via OIDC |
| `ECR_REGISTRY` | org or environment | `<account>.dkr.ecr.ap-southeast-3.amazonaws.com` |
| `ECS_CLUSTER` | environment | from Terraform |
| `ECS_SERVICE` | repo + environment | e.g. `rusuh-queue` |
| `ECS_TASK_FAMILY` | repo + environment | from Terraform |
| `ECS_CONTAINER` | repo + environment (optional) | defaults to `service` |

**Contract with the later Terraform (builder's call, to record in `docs/ci-cd.md`):** Terraform
owns the cluster, service, IAM and the *first* task definition; CD owns the image in later
revisions. Terraform must `ignore_changes` on the service's `task_definition` so an apply does
not roll the image back. No task-definition file lives in the backend repos.

ECR repo name = `service` input. Concurrency: one CD run per service per environment
at a time (`concurrency: cd-<service>-<environment>`, no cancel).

### Rollout

1. Create `rusuh-infra` (with David's OK), add the workflows, docs, examples; tag `v1`.
2. Add org variables (switch defaults).
3. In `rusuh-queue`, replace `ci.yml` with the caller. Same checks as today, sqlc drift as `extra`.
   Prove on a PR: checks run, image builds but does not push. Prove on a test tag with `CD_ECS=off`:
   summary shows what would deploy.
4. Later, when Backend 2's skeleton is ready: start `rusuh-core` from `examples/node-caller.yml`
   together with Backend 2 (not part of this plan).
5. After Terraform: set AWS variables, switch `CD_ECS=on`, tag a release.

Org settings, repo creation, variables and branch protection are outward actions:
each needs David's OK at the time.

## Constraints

- Commits follow `[<issue-code>] | david | <message>`, no AI attribution, no force push.
- Push via gh credential helper, never a token in a URL.
- Do not change the `Makefile` local tweak or `api/.apidog` in rusuh-queue; never commit `cmd/fakecore`.
- `rusuh-queue` `docs/` stays local.
- Deadline for the assessment: Fri 13 Nov 2026. rusuh-queue CI on the shared pipeline should be
  working well before then; CD to ECS depends on Terraform.

## Left to the builder

- Exact input names and the shape of the switch-resolving job.
- Image copy tool (`imagetools` vs `crane`).
- How the summary table looks.
- Action version pins (pin to major or SHA; be consistent).
- Node caller defaults (`npm ci`, `npm run lint`, `npm test`, `npm audit`); Backend 2 confirms.
