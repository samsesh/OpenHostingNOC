# Contributing to OpenHostingNOC

First off, thanks for taking the time to contribute!

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Table of Contents

- [Ways to Contribute](#ways-to-contribute)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Pull Request Guidelines](#pull-request-guidelines)
- [Commit Conventions](#commit-conventions)
- [Code Style](#code-style)
- [Testing](#testing)
- [Good First Issues](#good-first-issues)

## Ways to Contribute

- **Report bugs** — open a [Bug Report](https://github.com/samsesh/OpenHostingNOC/issues/new?template=bug_report.md)
- **Suggest features** — open a [Feature Request](https://github.com/samsesh/OpenHostingNOC/issues/new?template=feature_request.md)
- **Improve docs** — fix typos, add examples, clarify instructions
- **Add integrations** — new exporters, alert routes, or service configs
- **Write tests** — extend the BATS test suite in `tests/`
- **Review PRs** — comment on open pull requests

## Getting Started

### Prerequisites

- Docker 24.0+ & Compose v2.20+
- ShellCheck (`shellcheck`), yamllint (`pip install yamllint`)
- hadolint (`docker pull hadolint/hadolint`)
- BATS (`npm install -g bats`)

### Fork & Clone

```bash
git clone https://github.com/<your-username>/OpenHostingNOC.git
cd OpenHostingNOC
git remote add upstream https://github.com/samsesh/OpenHostingNOC.git
```

## Development Workflow

```bash
# Create a feature branch
git checkout -b feature/my-feature

# Make your changes

# Run lints
shellcheck scripts/*.sh
yamllint .
docker run --rm -v $(pwd):/mnt hadolint/hadolint hadolint /mnt/Dockerfile

# Run tests
bats tests/

# Commit
git commit -am 'feat: add my feature'

# Push
git push origin feature/my-feature
```

## Pull Request Guidelines

- Open PRs against the `Localhost` branch (not `main`)
- Reference any related issue: `Fixes #123`
- Keep PRs focused — one feature or fix per PR
- Ensure all status checks pass (CI, Tests, Docker)
- Update docs if your change adds or modifies configuration

### PR Checklist

- [ ] ShellCheck passes with no errors
- [ ] yamllint passes
- [ ] YAML/JSON configs are valid
- [ ] `bats tests/` passes
- [ ] New configs have matching test entries in `tests/`
- [ ] `.env.example` updated if new env vars added
- [ ] Wiki or docs updated if behavior changed

## Commit Conventions

We use [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix     | Example                          | Usage            |
|------------|----------------------------------|------------------|
| `feat:`    | `feat: add netdata container`    | New feature      |
| `fix:`     | `fix: correct traefik rate-limit`| Bug fix          |
| `ci:`      | `ci: pin actions to shas`       | CI/CD changes    |
| `docs:`    | `docs: update backup guide`     | Documentation    |
| `refactor:`| `refactor: extract healthcheck` | Code restructuring |
| `test:`    | `test: add config validation`   | Test additions   |
| `chore:`   | `chore: bump grafana to 11.2`   | Maintenance      |

## Code Style

### Shell Scripts
- `set -euo pipefail` at the top of every script
- 4-space indent, no tabs
- Prefer `[[ ]]` over `[ ]`
- Quote all variable expansions: `"$var"`
- Use `$()` over backticks

### YAML
- 2-space indent
- No trailing whitespace
- Use `---` at file start for Compose files

### Dockerfiles
- Pin base image versions (never `latest`)
- Use `--no-cache` for apk, `--no-install-recommends` for apt
- Combine `RUN` commands to reduce layers

## Testing

```bash
# Run full test suite
bats tests/

# Run specific test file
bats tests/test_configs.bats

# Run specific test
bats tests/test_configs.bats --filter "yaml"

# Run config validation only
bats tests/test_configs.bats && bats tests/test_scripts.bats
```

Tests are automatically run on every push via the [Tests workflow](.github/workflows/test.yml).

## Good First Issues

Look for issues labeled [`good first issue`](https://github.com/samsesh/OpenHostingNOC/labels/good%20first%20issue) — these are small, well-scoped tasks ideal for new contributors.

Issues labeled [`help wanted`](https://github.com/samsesh/OpenHostingNOC/labels/help%20wanted) need community assistance but may require more context.

## Need Help?

- Check the [Wiki](https://github.com/samsesh/OpenHostingNOC/wiki)
- Start a [Discussion](https://github.com/samsesh/OpenHostingNOC/discussions)
- Join the Issues page for existing conversations
