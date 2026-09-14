#!/usr/bin/env zsh

emulate -LR zsh
setopt errexit

readonly repo_root=${0:A:h:h}
readonly version=$(< "$repo_root/VERSION")

fail() {
  print -u2 -r -- "FAIL: $1"
  return 1
}

[[ $version =~ '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$' ]] ||
  fail "VERSION is not valid SemVer: $version"

grep -Fq 'img.shields.io/github/v/tag/zorgzerg/terragrunt-zsh-plugin?label=version&sort=semver' \
  "$repo_root/README.md" ||
  fail "README.md does not use the dynamic version badge"

grep -Eq "^## \[$version\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$" "$repo_root/CHANGELOG.md" ||
  fail "CHANGELOG.md has no dated $version release section"

grep -Fq "[$version]: https://github.com/zorgzerg/terragrunt-zsh-plugin/releases/tag/v$version" \
  "$repo_root/CHANGELOG.md" ||
  fail "CHANGELOG.md has no release link for v$version"

if [[ ${GITHUB_REF_TYPE:-} == tag ]]; then
  [[ ${GITHUB_REF_NAME:-} == "v$version" ]] ||
    fail "Git tag ${GITHUB_REF_NAME:-<unset>} does not match VERSION $version"
fi

print -r -- "Version consistency check passed: $version"
