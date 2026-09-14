# Terragrunt Zsh Plugin

[![Version](https://img.shields.io/github/v/tag/zorgzerg/terragrunt-zsh-plugin?label=version&sort=semver)](https://github.com/zorgzerg/terragrunt-zsh-plugin/tags) [![CI](https://github.com/zorgzerg/terragrunt-zsh-plugin/actions/workflows/ci.yml/badge.svg?branch=master&event=push)](https://github.com/zorgzerg/terragrunt-zsh-plugin/actions/workflows/ci.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Fast, version-aware Zsh completion and practical aliases for
[Terragrunt](https://github.com/gruntwork-io/terragrunt).

Releases follow [Semantic Versioning](https://semver.org/). The version badge
shows the latest published `vX.Y.Z` Git tag automatically.

After loading the plugin, print the installed version with:

```zsh
print -r -- "$TERRAGRUNT_ZSH_PLUGIN_VERSION"
```

The plugin reads command and option metadata from the installed Terragrunt
binary, so top-level and nested completion follows CLI updates without a static
command list. Terraform arguments are delegated to the Terraform completion
bundled with Oh My Zsh.

## Features

- Dynamic completion for Terragrunt commands, nested commands, and options.
- Terraform completion for shortcuts and commands after `terragrunt run --`.
- Resource address completion for `-target` and `-replace`.
- Root output name completion for `terragrunt output`.
- Per-unit completion cache with background refresh after state mutations.
- Short aliases for common Terragrunt workflows.

## Requirements

- Zsh 5.8 or newer.
- [Oh My Zsh](https://ohmyz.sh/).
- [Terragrunt](https://terragrunt.gruntwork.io/) 1.1 or newer.
- [HashiCorp Terraform](https://developer.hashicorp.com/terraform).
- [`jq`](https://jqlang.github.io/jq/) for single-request cache generation.

Without `jq`, resource and output completion still works, but falls back to
separate live queries and does not build the combined cache snapshot.

## Installation

Clone the repository into the Oh My Zsh custom plugin directory:

```zsh
git clone https://github.com/zorgzerg/terragrunt-zsh-plugin \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/terragrunt"
```

Add `terragrunt` to the plugin list in `~/.zshrc`:

```zsh
plugins=(git terragrunt)
```

Start a new shell:

```zsh
exec zsh
```

## Usage

Press `TAB` after a Terragrunt command, option, resource address, or output
prefix:

```zsh
terragrunt <TAB>
tga -target=<TAB>
tgp -replace=<TAB>
tgo <TAB>
terragrunt run -- state <TAB>
```

### Aliases

| Alias | Command |
| --- | --- |
| `tg` | `terragrunt` |
| `tga` | `terragrunt apply` |
| `tgc` | `terragrunt run -- console` |
| `tgd` | `terragrunt destroy --use-partial-parse-config-cache` |
| `tgf` | `terragrunt hcl fmt` |
| `tgi` | `terragrunt init --use-partial-parse-config-cache` |
| `tgiu` | `terragrunt init -upgrade --use-partial-parse-config-cache` |
| `tgo` | `terragrunt output --use-partial-parse-config-cache` |
| `tgoj` | `terragrunt output -json --use-partial-parse-config-cache` |
| `tgp` | `terragrunt plan --use-partial-parse-config-cache` |
| `tgv` | `terragrunt validate` |
| `tgs` | `terragrunt state --use-partial-parse-config-cache` |
| `tgt` | `terragrunt run -- taint` |
| `tgsh` | `terragrunt show` |

`terraform taint` is deprecated. Prefer `tgp -replace=<resource>` followed by
`tga` for new workflows.

## Completion Cache

Resource addresses and root output names are stored in each Terragrunt unit:

```text
.terragrunt-cache/.zsh-completion/
├── outputs
└── resources
```

On a cache miss, one read-only `terragrunt show -json` request populates both
files. Only resource addresses and output names are stored; output values are
never written to the cache.

The cache refreshes in the background after these commands return to the
prompt:

- `apply`, `destroy`, `import`, `refresh`, `taint`, and `untaint`;
- `state mv`, `state rm`, `state push`, and `state replace-provider`;
- `workspace new`, `workspace select`, and `workspace delete`.

Automatic refresh applies to commands run from an interactive Zsh session with
this plugin loaded. If another process changes the state, invalidate the cache
manually; the next completion rebuilds it:

```zsh
rm -rf .terragrunt-cache/.zsh-completion
```

## Updating

```zsh
git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/terragrunt" pull --ff-only
exec zsh
```

To install a specific release instead of tracking `master`:

```zsh
git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/terragrunt" \
  checkout vX.Y.Z
exec zsh
```

## Troubleshooting

Confirm that completion is registered:

```zsh
print -r -- "${_comps[terragrunt]}"
```

The expected value is `_terragrunt`. If `compinit` reports insecure
directories, ensure the plugin is not writable by group or others:

```zsh
chmod go-w "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/terragrunt"
exec zsh
```

For cache-related issues, remove the unit cache as described above and verify
that `terragrunt show -json` succeeds in the same directory.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development and test instructions.
Security reports should follow [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE)
