# Contributing

## Development Workflow

1. Fork & clone the repository
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Run `make fmt` and `make validate` before committing
4. Open a Pull Request — the CI pipeline will run automatically

## Module Development Guidelines

- Each module must have `variables.tf`, `outputs.tf`, and `main.tf`
- All variables must have descriptions
- Use `validation` blocks for critical variables
- Tag all resources using `var.tags`
- Use `lifecycle { ignore_changes = [...] }` for volatile attributes

## Commit Convention

```
feat: add redis cache module
fix: correct NSG priority conflict
docs: update architecture diagram
refactor: extract monitoring alerts to submodule
```

## Testing

```bash
# Format
make fmt

# Validate
make validate

# Security scan
make lint

# Plan before opening PR
make plan ENV=dev
```
