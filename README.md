# AIDLC Plugin

AI Development Life Cycle plugin for Claude Code. Provides a fully AI-driven development workflow: develop, check, review, fix, and PR creation — all orchestrated by AI agents with human approval gates.

## Installation

```bash
# Add the marketplace
claude plugins marketplace add Fraser27/aidlc-plugin

# Install the plugin
claude plugins install aidlc-plugin
```

After installing, reload plugins with `/plugins` or restart your Claude Code session for skills to become available.

## Quick Start

Initialize AIDLC for your project:
```
/aidlc-init
```

Ship a feature (full lifecycle):
```
/aidlc-ship "add retry logic to the query lambda"
```

Review current branch independently:
```
/aidlc-review
```

## How It Works

1. **Develop** — Creates branch, implements change using TDD
2. **Self-Check** — Runs formatting, linting, type checks, tests, security, dep audit, IaC validation
3. **Review** — Spawns independent reviewer agent (no implementation context)
4. **Fix** — Addresses critical/high findings (max 3 cycles)
5. **Human Gate** — Presents summary, waits for approval
6. **PR Creation** — Creates PR with structured body

## Configuration

Create `.aidlc.yml` in your project root (or use `/aidlc-init`):

```yaml
version: 1
tools:
  formatter: "ruff format"
  linter: "ruff check"
  test: "pytest --cov=. --cov-report=term-missing"
  security: "bandit -r ."
  type_check: "mypy ."
  iac_validate: "cdk synth --quiet"
  dep_audit: "pip-audit"
coverage:
  min: 80
  fail_on_drop: 5
review:
  threshold: "high"
  max_fix_cycles: 3
exclude:
  - "node_modules/"
  - ".venv/"
  - "cdk.out/"
branch_prefix: "aidlc"
```

## Supported Languages

| Language | Formatter | Linter | Security | Types | Deps |
|----------|-----------|--------|----------|-------|------|
| Python | ruff format | ruff check | bandit | mypy | pip-audit |
| TypeScript/JS | prettier | eslint | semgrep | tsc | npm audit |
| Go | gofmt | golangci-lint | gosec | built-in | govulncheck |
| Rust | rustfmt | clippy | cargo-audit | built-in | cargo-audit |

## IaC Support

- AWS CDK (`cdk synth`)
- Terraform (`terraform validate`)
- SAM (`sam validate`)

## License

MIT
