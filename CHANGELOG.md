# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Dynamic completion based on the installed Terragrunt CLI.
- Terraform completion delegation for shortcuts and `run --`.
- Resource address completion for `-target` and `-replace`.
- Root output name completion.
- Per-unit completion cache with background refresh after state mutations.
- Explicit completion support for all bundled aliases.

### Changed

- Updated aliases for Terragrunt 1.1.
- Replaced legacy static Terraform and Terragrunt command definitions.

### Removed

- Deprecated Terragrunt commands and legacy `--terragrunt-*` flags.
