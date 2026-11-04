# Shared backend CI/CD

Two reusable workflows that every Rusuh backend calls:

- `.github/workflows/backend-ci.yml`: checks, image build and the release check.
- `.github/workflows/backend-cd.yml`: copies the release image to ECR and deploys it.

Design and reasons: [`superpowers/specs/2026-11-04-shared-ci-cd-design.md`](superpowers/specs/2026-11-04-shared-ci-cd-design.md).

## Plug a repo in

1. Copy [`examples/go-caller.yml`](../examples/go-caller.yml) or [`examples/node-caller.yml`](../examples/node-caller.yml) to `.github/workflows/ci.yml` in the repo.
2. Set `service` (both jobs) to the repo's image name, and the commands to the repo's own.
3. Open a PR. The run summary lists every switch and which commands are configured.

Callers pin `@v1`. `v1` moves to the newest `v1.x.y` release of this repo.

## What runs when

| Event | CI | CD |
| --- | --- | --- |
| Pull request | checks, image built (not pushed) | no |
| Push to `main` | checks, image built and pushed to GHCR | no |
| Push of a `v*` tag | `verify-release` only: the commit is on `main` and its GHCR image exists | yes, after CI |

Image: `ghcr.io/pt-meeting-sampai-malam-konsultasi/<service>:<full commit sha>`, platforms `linux/amd64,linux/arm64`. A release never rebuilds: CD copies that image.

## CI inputs

| Input | Required | Default | Meaning |
| --- | --- | --- | --- |
| `service` | yes | | image name, lowercase |
| `runtime` | yes | | `go` or `node` |
| `runtime-version-file` | yes | | path from repo root, e.g. `go.mod`, `.nvmrc` |
| `working-directory` | no | `.` | where commands run and the Docker build context |
| `setup` | no | empty | e.g. `npm ci` |
| `format` | no | empty | runs with the `CI_LINT` switch |
| `lint` | no | empty | runs with the `CI_LINT` switch |
| `vuln` | no | empty | runs with the `CI_VULN` switch |
| `test` | no | empty | runs with the `CI_TEST` switch |
| `extra` | no | empty | repo-only checks, always run |
| `platforms` | no | `linux/amd64,linux/arm64` | image platforms |
| `switch-overrides` | no | empty | JSON, for this repo's self-test only |

An empty command is skipped and shown as "not configured". Commands run in bash with `-e -o pipefail`; multi-line commands are fine.

The caller grants `contents: read, packages: write` to the CI job.

## CD inputs

| Input | Required | Default |
| --- | --- | --- |
| `service` | yes | |
| `environment` | no | `production` |

The caller grants `contents: read, packages: read, id-token: write` to the CD job.

## Switches

Each switch is a GitHub Actions variable. Values are exactly `on` or `off`; anything else fails the run.

| Variable | Default when unset | Stage |
| --- | --- | --- |
| `CI_LINT` | on | `format` and `lint` |
| `CI_TEST` | on | `test` |
| `CI_VULN` | on | `vuln` |
| `CI_IMAGE` | on | image build |
| `CD_ECS` | off | ECR copy and ECS deploy |
| `CD_K3S` | off | k3s deploy (not implemented; fails if on) |

- **Central default:** set the variable at the org (Settings → Secrets and variables → Actions → Variables).
- **Repo override:** set a variable with the same name in the repo. The repo value wins for that repo.
- **Back to the default:** delete the repo variable.

A switched-off stage is skipped, never failed.

## CD variables

Set on the GitHub Environment named by `environment` (e.g. `production`) in each backend repo, or at the org when shared.

| Variable | Example |
| --- | --- |
| `AWS_REGION` | `ap-southeast-3` |
| `AWS_ROLE_ARN` | role GitHub assumes through OIDC |
| `ECR_REGISTRY` | `<account>.dkr.ecr.ap-southeast-3.amazonaws.com` |
| `ECS_CLUSTER` | from Terraform |
| `ECS_SERVICE` | e.g. `rusuh-queue` |
| `ECS_TASK_FAMILY` | from Terraform |
| `ECS_CONTAINER` | optional, defaults to `service` |

With `CD_ECS=on`, a missing variable fails the run before anything touches AWS. The ECR repository is named after `service`. No AWS keys are stored anywhere: the role is assumed through GitHub OIDC.

## Contract with Terraform

- Terraform owns the ECR repositories, cluster, services, IAM (including the OIDC role) and the first task definition of each service.
- CD owns the image in later task definition revisions: it reads the latest revision of `ECS_TASK_FAMILY`, swaps the image of `ECS_CONTAINER`, registers it and updates the service.
- Terraform sets `lifecycle { ignore_changes = [task_definition] }` on each `aws_ecs_service`, so an apply does not roll an image back.

## Release checklist

1. Merge to `main`.
2. Wait for `main` CI to be green; its image is now in GHCR.
3. If the release needs database migrations, apply them by hand first. CD does not run migrations.
4. Push the tag: `git tag vX.Y.Z && git push origin vX.Y.Z`.

When every CD switch is off, the tag run still writes a "Dry run: nothing deployed" summary.

## Required status checks

Filled in after the first live run on `rusuh-queue`.

## Releasing this repo

1. Merge to `main`; the `self-test` workflow must be green.
2. Run the negative self-test: `gh workflow run self-test.yml -f negative=true`. `bad-switch` and `cd-missing-config` must fail with their messages; the rest must pass.
3. Tag `v1.x.y` and move `v1` to the same commit.
