# Contributing

Thanks for your interest in contributing!

## Reporting Bugs

Open a [GitHub Issue](../../issues/new?template=bug_report.md) with:
- Steps to reproduce
- Expected vs actual behaviour
- Your `gcloud version` output and OS/Bash version

## Submitting Changes

1. Fork the repository
2. Create a branch: `git checkout -b feature/my-change`
3. Make your changes
4. Open a Pull Request against `main`

## Code Style

- Keep the script compatible with **Bash 3.2+** (macOS system default) — no `mapfile`, associative arrays, or other Bash 4+ features
- No external dependencies beyond `gcloud`
- All variables used in shell expansions must be double-quoted
- Test with `DRY_RUN=true` before submitting changes that affect the migration logic
