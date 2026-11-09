# Shared backend CI/CD

Everything for CI/CD lives in this folder, except the workflows themselves: GitHub only runs reusable workflows from
`.github/workflows/` (`backend-ci.yml`, `backend-cd.yml`, `cicd-self-test.yml`). Lint both with `make -C ci-cd lint`
from the repo root.

Two reusable workflows that every Rusuh backend calls:

- `.github/workflows/backend-ci.yml`: checks, image build and the release check.
- `.github/workflows/backend-cd.yml`: copies the release image to ECR and deploys it.

Design and reasons: [`docs/2026-11-04-shared-ci-cd-design.md`](docs/2026-11-04-shared-ci-cd-design.md).

## Plug a repo in

1. Copy [`examples/go-caller.yml`](examples/go-caller.yml) or [`examples/node-caller.yml`](examples/node-caller.yml) to `.github/workflows/ci.yml` in the repo.
2. Set `service` (both jobs) to the repo's image name, and the commands to the repo's own.
3. Open a PR. The run summary lists every switch and which commands are configured.

Callers pin `@v1`. `v1` moves to the newest `v1.x.y` release of this repo.

### Monorepo

A repo with more than one service (rusuh-core has six apps) cannot use one
caller per repo: the CI builds one image per call and the CD deploys one
service per call. Use one caller file with a matrix over the apps
([`examples/node-monorepo-caller.yml`](examples/node-monorepo-caller.yml)):
each matrix entry sets the image name, the workspace package, the Dockerfile
(`apps/<app>/Dockerfile`, built from the repo root as context) and the
per-service CD values (`ecs-service`, `ecs-task-family`, `ecs-container`).
The shared values (`AWS_REGION`, `AWS_ROLE_ARN`, `ECR_REGISTRY`,
`ECS_CLUSTER`) still come from vars.

## What runs when

| Event | CI | CD |
| --- | --- | --- |
| Pull request | checks, image built and scanned (not pushed) | no |
| Push to `main` | checks, image built, scanned and pushed to GHCR | no |
| Push of a `v*` tag | `verify-release` only: the tag is `vX.Y.Z` (optionally `-hotfix.N` / `-bugfix.N`), the commit is on `main` and its GHCR image exists | yes, after CI |

`checks` runs, in order:
1. the secret scan (gitleaks over the working directory);
2. the Dockerfile lint (hadolint, fails from `warning` up; skipped with a note when there is no `Dockerfile`);
3. setup, then `format`, `lint`, `vuln`, `test`, `sast`, `coverage` and `extra`.

`image` builds `linux/amd64` first and scans it with Trivy. It fails on HIGH or CRITICAL issues that have a fix.
Only then does it build all platforms (from the same cache) and push.

Image: `ghcr.io/pt-meeting-sampai-malam-konsultasi/<service>:<full commit sha>`, platforms `linux/amd64,linux/arm64`. A release never rebuilds: CD copies that image.

## CI inputs

| Input | Required | Default | Meaning |
| --- | --- | --- | --- |
| `service` | yes | | image name, lowercase |
| `runtime` | yes | | `go` or `node` |
| `runtime-version-file` | yes | | path from repo root, e.g. `go.mod`, `.nvmrc` |
| `working-directory` | no | `.` | where commands run and the Docker build context |
| `dockerfile` | no | `Dockerfile` | path to the Dockerfile, relative to the repo root |
| `context` | no | `working-directory` | Docker build context; when empty, falls back to `working-directory` |
| `setup` | no | empty | e.g. `npm ci` |
| `format` | no | empty | runs with the `CI_LINT` switch |
| `lint` | no | empty | runs with the `CI_LINT` switch |
| `vuln` | no | empty | runs with the `CI_VULN` switch |
| `test` | no | empty | runs with the `CI_TEST` switch |
| `sast` | no | empty | static security analysis, e.g. gosec; runs with the `CI_SAST` switch |
| `coverage` | no | empty | prints a coverage line into the run summary (no gate); runs with the `CI_TEST` switch, after `test` |
| `extra` | no | empty | repo-only checks, always run |
| `platforms` | no | `linux/amd64,linux/arm64` | image platforms |
| `switch-overrides` | no | empty | JSON, for this repo's self-test only |
| `release-tag` | no | empty | checks this tag as if it had been pushed; for this repo's self-test only |

An empty command is skipped and shown as "not configured". Commands run in bash with `-e -o pipefail`; multi-line commands are fine.

The caller grants `contents: read, packages: write` to the CI job.

## CD inputs

| Input | Required | Default |
| --- | --- | --- |
| `service` | yes | |
| `environment` | no | `production` |
| `ecs-service` | no | `ECS_SERVICE` var |
| `ecs-task-family` | no | `ECS_TASK_FAMILY` var |
| `ecs-container` | no | `ECS_CONTAINER` var |
| `smoke-url` | no | `SMOKE_URL` var |

Each of these falls back to the GitHub Actions variable of the same name when
the input is empty. `ecs-container` is required in practice for our services:
the container names in Terraform are the short names (`auth`, `core`, `queue`,
…), not the image names (`rusuh-auth`, `rusuh-core`, …), so pass it as an
input or set the var — the old default of the service name does not match.

The caller grants `contents: read, packages: read, id-token: write` to the CD job.

## Switches

Each switch is a GitHub Actions variable. Values are exactly `on` or `off`; anything else fails the run.

| Variable | Default when unset | Stage |
| --- | --- | --- |
| `CI_LINT` | on | `format` and `lint` |
| `CI_TEST` | on | `test` |
| `CI_VULN` | on | `vuln` |
| `CI_IMAGE` | on | image build |
| `CI_SAST` | on | `sast` |
| `CI_SECRETS` | on | secret scan (gitleaks) |
| `CI_IMAGE_SCAN` | on | image scan (Trivy) before any push |
| `CD_ECS` | off | ECR copy and ECS deploy |
| `CD_K3S` | off | k3s deploy (not implemented; fails if on) |

- **Central default:** set the variable at the org (Settings → Secrets and variables → Actions → Variables).
- **Repo override:** set a variable with the same name in the repo. The repo value wins for that repo.
- **Back to the default:** delete the repo variable.

A switched-off stage is skipped, never failed.

- `CD_*` switches must be org or repo variables, **never environment variables**: they are read before the deploy jobs enter the environment, so an environment-level `CD_ECS` is ignored.
- Turn `CD_ECS` on **per repo** (repo variable), not at the org, so each service starts deploying only when its AWS side exists.
- The per-repo override is proven on `rusuh-queue` (set `CI_VULN=off`, see it skipped, delete it); do this before relying on `@v1` in a new org.

## CD variables

Set on the GitHub Environment named by `environment` (e.g. `production`) in each backend repo, or at the org when shared.

`ECS_SERVICE`, `ECS_TASK_FAMILY`, `ECS_CONTAINER` and `SMOKE_URL` are
per-service: pass them as inputs to the CD job (monorepo/matrix callers) or
set them as vars (single-service callers). The rest (`AWS_REGION`,
`AWS_ROLE_ARN`, `ECR_REGISTRY`, `ECS_CLUSTER`) are shared per environment.

| Variable | Example |
| --- | --- |
| `AWS_REGION` | `ap-southeast-3` |
| `AWS_ROLE_ARN` | role GitHub assumes through OIDC |
| `ECR_REGISTRY` | `<account>.dkr.ecr.ap-southeast-3.amazonaws.com` |
| `ECS_CLUSTER` | from Terraform |
| `ECS_SERVICE` | e.g. `rusuh-queue` |
| `ECS_TASK_FAMILY` | from Terraform |
| `ECS_CONTAINER` | optional, defaults to `service` |
| `SMOKE_URL` | optional; after the deploy is stable, CD needs a 2xx from it (10 retries, 6 s apart), e.g. `https://api.example/readyz` |

With `CD_ECS=on`, a missing variable fails the run before anything touches AWS. The ECR repository is named after `service`. No AWS keys are stored anywhere: the role is assumed through GitHub OIDC.

## Production protection (required before `CD_ECS=on`)

The tag check in `backend-cd.yml` stops honest mistakes, not a determined collaborator: a PR can edit its own caller file. AWS access is guarded by the platform:

1. In each backend repo, the `production` environment's deployment policy allows only tags matching `v*`.
2. A tag ruleset limits who can create `v*` tags.
3. The IAM role's OIDC trust policy is pinned to `token.actions.githubusercontent.com:sub` = the rusuh-core and rusuh-queue repos in the `production` environment (`repo:PT-Meeting-Sampai-Malam-Konsultasi/rusuh-core:environment:production`, `repo:PT-Meeting-Sampai-Malam-Konsultasi/rusuh-queue:environment:production`), and `job_workflow_ref` to `PT-Meeting-Sampai-Malam-Konsultasi/rusuh-infra/.github/workflows/backend-cd.yml@refs/tags/v1`.

Fork PRs get no `id-token` and a read-only token, so they cannot push images or reach AWS.

## Contract with Terraform

- Terraform owns the ECR repositories, cluster, services, IAM (including the OIDC role) and the first task definition of each service.
- CD owns the image in later task definition revisions: it reads the latest revision of `ECS_TASK_FAMILY`, swaps the image of `ECS_CONTAINER`, registers it and updates the service.
- Terraform sets `lifecycle { ignore_changes = [task_definition] }` on each `aws_ecs_service`, so an apply does not roll an image back.
- Terraform creates the OIDC role with the trust conditions in "Production protection".

## Release checklist

1. Merge to `main`.
2. Wait for `main` CI to be green; its image is now in GHCR.
3. If the release needs database migrations, apply them by hand first. CD does not run migrations.
4. Push the tag: `git tag vX.Y.Z && git push origin vX.Y.Z`. A fix on top of a release is `vX.Y.Z-hotfix.N` or
   `vX.Y.Z-bugfix.N`. Any other `v*` tag fails `verify-release`.

When every CD switch is off, the tag run still writes a "Dry run: nothing deployed" summary.

## Required status checks

A caller job named `ci` reports these checks. Make them required on `main` in every service repo:

| Check | What it covers |
| --- | --- |
| `ci / checks` | format, lint, vuln, test with coverage, SAST, secrets, Dockerfile lint, `extra` |
| `ci / image` | the image build, with the Trivy scan before any push |

Leave `ci / switches` (always green) and `ci / verify-release` (tags only) unrequired.

**Set up so far:** `rusuh-queue` (7 Nov), with "require branches to be up to date".

## Releasing this repo

1. Merge to `main`; the `self-test` workflow must be green.
2. Run the negative self-test: `gh workflow run cicd-self-test.yml -f negative=true`. These must fail with their
   messages, and the rest must pass:
   - `bad-switch`;
   - `cd-missing-config`;
   - `bad-dockerfile` (hadolint DL3007);
   - `leaky` (gitleaks);
   - `vulnerable-image` (Trivy);
   - `bad-tag` (tag pattern).
3. Tag `v1.x.y` and move `v1` to the same commit.

## Images that pass the scan

- **Node:** the official `node` images ship npm, and npm's own dependencies often carry fixed HIGH issues that Trivy
  reports. Install the dependencies in a build stage, and remove npm, npx and corepack from the runtime stage (see
  `ci-cd/tests/fixtures/node-app/Dockerfile`). The app does not need them to run.
- **Go:** a static binary on `gcr.io/distroless/static-debian12:nonroot` scans clean (`ci-cd/tests/fixtures/go-app`).

## Stages adopted from the corporate template

On 6 Nov the Telkomsel GitLab stage templates were compared with this pipeline. The full table is in the spec,
[`ci-cd/docs/2026-11-04-shared-ci-cd-design.md`](docs/2026-11-04-shared-ci-cd-design.md), under "Update 6 Nov".

- **Adopted:**
  - gosec (`sast`);
  - gitleaks;
  - hadolint;
  - Trivy;
  - a coverage summary;
  - the post-deploy smoke check (`SMOKE_URL`);
  - `-hotfix.N` / `-bugfix.N` release tags.
- **Later:** Sonar and DAST.
- **Not adopted:** multi-environment by branch, Kong, blue-green, Helm, and the Telkomsel-internal tools.

