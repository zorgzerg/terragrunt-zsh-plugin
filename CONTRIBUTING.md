# Contributing

Contributions are welcome. Keep changes focused and consistent with the current
Zsh implementation.

## Development Setup

1. Fork and clone the repository.
2. Install Zsh 5.8 or newer and `jq`.
3. Install Terraform and Terragrunt when testing live completion behavior.
4. Run the test suite:

```zsh
zsh tests/test_plugin.zsh
```

1. Check syntax and whitespace:

```zsh
zsh -n _terragrunt terragrunt.plugin.zsh tests/*.zsh
zsh tests/check_version.zsh
git diff --check
```

## Releasing

Versions follow Semantic Versioning. `VERSION` is the source of truth, the
README badge follows published tags, and `CHANGELOG.md` records each release.

1. Create a version branch such as `v1.1.0`.
1. Update `VERSION` to `1.1.0`.
1. Add a dated `[1.1.0]` section to the top of `CHANGELOG.md` and add its
  release link at the bottom of the file.
1. Run the complete test suite and merge the release branch into `master`.
1. Create an annotated tag from the release commit and push it:

```zsh
git tag -a v1.1.0 -m "Release v1.1.0"
git push origin v1.1.0
```

Version branches contain release preparation and fixes. Git tags with the same
name are the canonical identifiers for published releases.

## Pull Requests

- Explain the user-visible behavior being changed.
- Add or update tests for completion routing, aliases, or cache behavior.
- Update `README.md` and `CHANGELOG.md` when behavior changes.
- Do not include credentials, Terraform state, `.terraform`, or
  `.terragrunt-cache` content.
- Keep compatibility with HashiCorp Terraform; OpenTofu compatibility is not a
  project requirement.

## Testing Live Completion

Install the working tree as the `terragrunt` custom plugin, start a fresh shell,
and test the affected command in a disposable Terragrunt unit:

```zsh
exec zsh
terragrunt <TAB>
tgp -target=<TAB>
tgo <TAB>
```

Commands used by completion to inspect state are read-only. Do not use a
production backend when testing changes that execute Terragrunt commands beyond
completion.
