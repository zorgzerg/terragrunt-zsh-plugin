#!/usr/bin/env zsh

emulate -LR zsh
setopt errexit pipefail

readonly repo_root=${0:A:h:h}
readonly temp_root=$(mktemp -d)
readonly unit_dir="$temp_root/unit"
readonly bin_dir="$temp_root/bin"
readonly calls_file="$temp_root/calls"

cleanup() {
  rm -rf -- "$temp_root"
}

fail() {
  print -u2 -r -- "FAIL: $1"
  return 1
}

assert_equal() {
  local expected=$1
  local actual=$2
  local message=$3

  [[ $actual == $expected ]] || fail "$message (expected '$expected', got '$actual')"
}

assert_contains() {
  local expected=$1
  local message=$2
  shift 2

  (( ${@[(Ie)$expected]} > 0 )) || fail "$message (missing '$expected')"
}

mkdir -p -- "$unit_dir" "$bin_dir"
: >| "$unit_dir/terragrunt.hcl"

cat > "$bin_dir/terragrunt" <<'FAKE_TERRAGRUNT'
#!/bin/sh
printf '%s\n' "$*" >> "$TG_TEST_CALLS"

case "$*" in
  "--help")
    cat <<'HELP'
   run            Run an OpenTofu/Terraform command.
   apply          Create or update infrastructure.
   output         Show output values from your root module.
   hcl            Interact with HCL files.
   --log-level value  Set the log level.
   --help, -h         Show help.
HELP
    ;;
  "apply --help"|"output --help")
    cat <<'HELP'
   This is a shortcut for the command `terragrunt run`.
HELP
    ;;
  "hcl --help")
    printf '%s\n' '   fmt  Format HCL files.'
    ;;
  "hcl fmt --help")
    printf '%s\n' '   --check  Check formatting.'
    ;;
  "show -json --log-disable --non-interactive --experiment optional-dependency-outputs --no-dependency-outputs")
    cat <<'JSON'
{"values":{"root_module":{"resources":[{"address":"aws_instance.root"}],"child_modules":[{"resources":[{"address":"module.app.aws_instance.web[0]"}]}]},"outputs":{"endpoint":{"sensitive":false,"value":"example.invalid"},"private_ip":{"sensitive":false,"value":"10.0.0.1"}}}}
JSON
    ;;
  "state list --experiment optional-dependency-outputs --no-dependency-outputs")
    printf '%s\n' 'aws_instance.live' 'module.live.aws_s3_bucket.logs'
    ;;
  "output -json --log-disable --experiment optional-dependency-outputs --no-dependency-outputs")
    printf '%s\n' '{"live_endpoint":{"value":"example.invalid"},"live_ip":{"value":"10.0.0.2"}}'
    ;;
  "output --log-disable --experiment optional-dependency-outputs --no-dependency-outputs")
    printf '%s\n' 'fallback_endpoint = "example.invalid"' 'fallback_ip = "10.0.0.3"'
    ;;
  *)
    exit 1
    ;;
esac
FAKE_TERRAGRUNT
chmod 755 "$bin_dir/terragrunt"

export PATH="$bin_dir:$PATH"
export TG_TEST_CALLS=$calls_file

typeset -gA _comps
compdef() {
  local completion_function=$1
  shift
  local command_name
  for command_name in "$@"; do
    _comps[$command_name]=$completion_function
  done
}

source "$repo_root/terragrunt.plugin.zsh"
source "$repo_root/terragrunt.plugin.zsh"

assert_equal "$(< "$repo_root/VERSION")" "$TERRAGRUNT_ZSH_PLUGIN_VERSION" \
  "Runtime plugin version"

preexec_matches=( ${(M)preexec_functions:#_terragrunt_cache_preexec} )
precmd_matches=( ${(M)precmd_functions:#_terragrunt_cache_precmd} )
assert_equal 1 "${#preexec_matches}" "Single preexec hook"
assert_equal 1 "${#precmd_matches}" "Single precmd hook"
add-zsh-hook -d preexec _terragrunt_cache_preexec
add-zsh-hook -d precmd _terragrunt_cache_precmd

_describe() { return 0 }
_files() { return 0 }
_normal() { return 1 }
words=(terragrunt '')
CURRENT=2
source "$repo_root/_terragrunt"

assert_equal _terragrunt "${_comps[terragrunt]}" "Terragrunt completion registration"
assert_equal _terragrunt_alias "${_comps[tga]}" "Alias completion registration"

described_candidates=()
_describe() {
  local array_name=${@[-1]}
  described_candidates+=("${(@P)array_name}")
}

words=(terragrunt '')
CURRENT=2
_terragrunt_alias
assert_contains 'run:Run an OpenTofu/Terraform command.' \
  "Completion after automatic alias expansion" "${described_candidates[@]}"
assert_equal terragrunt "$words[1]" "Expanded command restoration"
assert_equal 2 "$CURRENT" "Expanded cursor restoration"

described_candidates=()
words=(tg '')
CURRENT=2
_terragrunt_alias
assert_contains 'run:Run an OpenTofu/Terraform command.' \
  "Completion with COMPLETE_ALIASES" "${described_candidates[@]}"
assert_equal tg "$words[1]" "Alias command restoration"
assert_equal 2 "$CURRENT" "Alias cursor restoration"

_describe() { return 0 }

reply_commands=()
reply_command_names=()
reply_options=()
_terragrunt_parse_help <<'HELP'
   run            Run a command.
   find, fd       Find units.
   --log-level value  Set log level.
   --help, -h         Show help.
HELP
assert_contains 'run:Run a command.' "Command parsing" "${reply_commands[@]}"
assert_contains 'fd:Find units.' "Command alias parsing" "${reply_commands[@]}"
assert_contains '--log-level:Set log level.' "Option parsing" "${reply_options[@]}"
assert_contains '-h:Show help.' "Short option parsing" "${reply_options[@]}"

: >| "$calls_file"
_terragrunt_refresh_completion_cache "$unit_dir"
call_lines=()
while IFS= read -r line; do call_lines+=("$line"); done < "$calls_file"
resource_lines=()
while IFS= read -r line; do resource_lines+=("$line"); done < "$unit_dir/.terragrunt-cache/.zsh-completion/resources"
output_lines=()
while IFS= read -r line; do output_lines+=("$line"); done < "$unit_dir/.terragrunt-cache/.zsh-completion/outputs"
assert_equal 1 "${#call_lines}" "Single snapshot request"
assert_equal \
  'show -json --log-disable --non-interactive --experiment optional-dependency-outputs --no-dependency-outputs' \
  "$call_lines[1]" \
  "Snapshot command"
assert_equal $'aws_instance.root\nmodule.app.aws_instance.web[0]' \
  "${(F)resource_lines}" \
  "Resource cache"
assert_equal $'endpoint\nprivate_ip' \
  "${(F)output_lines}" \
  "Output cache"
if grep -R -F 'example.invalid' "$unit_dir/.terragrunt-cache/.zsh-completion" >/dev/null; then
  fail "Output values must not be cached"
fi

captured_candidates=()
compadd() {
  local separator=${@[(i)-]}
  captured_candidates=("${@[$((separator + 1)),-1]}")
}
cd -- "$unit_dir"
_terragrunt_state_resources
assert_contains 'aws_instance.root' "Cached resource completion" "${captured_candidates[@]}"
assert_contains 'module.app.aws_instance.web[0]' "Nested resource completion" "${captured_candidates[@]}"

captured_candidates=()
_terragrunt_outputs
assert_contains endpoint "Cached output completion" "${captured_candidates[@]}"
assert_contains private_ip "Second cached output completion" "${captured_candidates[@]}"
call_lines=()
while IFS= read -r line; do call_lines+=("$line"); done < "$calls_file"
assert_equal 1 "${#call_lines}" "Cache reuse without backend requests"

rm -rf -- "$unit_dir/.terragrunt-cache/.zsh-completion"
functions[_saved_cache_refresh]=${functions[_terragrunt_refresh_completion_cache]}
_terragrunt_refresh_completion_cache() { return 0 }

captured_candidates=()
_terragrunt_state_resources
assert_contains 'aws_instance.live' "Live resource fallback" "${captured_candidates[@]}"
assert_contains 'module.live.aws_s3_bucket.logs' "Nested live resource fallback" "${captured_candidates[@]}"

captured_candidates=()
_terragrunt_outputs
assert_contains live_endpoint "Live output fallback" "${captured_candidates[@]}"
assert_contains live_ip "Second live output fallback" "${captured_candidates[@]}"

saved_path=$PATH
PATH=$bin_dir
hash -r
captured_candidates=()
_terragrunt_outputs
assert_contains fallback_endpoint "Output fallback without jq" "${captured_candidates[@]}"
assert_contains fallback_ip "Second output fallback without jq" "${captured_candidates[@]}"
PATH=$saved_path
hash -r
functions[_terragrunt_refresh_completion_cache]=${functions[_saved_cache_refresh]}

for command_line in \
  'terragrunt apply' \
  'terragrunt run -- destroy' \
  'terragrunt state rm module.app' \
  'terragrunt workspace select dev'; do
  _terragrunt_command_changes_state "$command_line" || fail "Mutation not detected: $command_line"
done

for command_line in \
  'terragrunt plan' \
  'terragrunt output' \
  'terragrunt state list' \
  'terragrunt state rm --help'; do
  if _terragrunt_command_changes_state "$command_line"; then
    fail "Read-only command treated as mutation: $command_line"
  fi
done

_terragrunt_cache_preexec '' 'terragrunt apply' ''
assert_equal "$unit_dir" "$_terragrunt_cache_refresh_dir" "Mutation unit capture"

cleanup
print 'All plugin tests passed.'
