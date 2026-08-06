#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"

json_line="$(jq -r '
  [
    (.model.display_name // ""),
    (.workspace.current_dir // .cwd // ""),
    (.version // ""),
    (.effort.level // ""),
    ((.context_window.current_usage // {})
      | (.input_tokens // 0)
        + (.output_tokens // 0)
        + (.cache_creation_input_tokens // 0)
        + (.cache_read_input_tokens // 0))
  ] | map(tostring) | join("\u001f")
' <<<"$input" 2>/dev/null || true)"

# unit separator, not tab: tab is IFS whitespace and would collapse empty fields
IFS=$'\037' read -r model_name cwd version effort used_tokens <<<"${json_line:-}"

# drop trailing parenthetical from the model name, e.g. "Opus 5 (1M context)" -> "Opus 5"
model_name="${model_name%% (*}"
if [[ -n "$effort" ]]; then
  model_name="$model_name  $effort"
fi

home="${HOME:-}"
display_cwd="$cwd"
if [[ -n "$home" && "$cwd" == "$home"* ]]; then
  display_cwd="~${cwd#"$home"}"
fi

git_segment=""
if [[ -n "$cwd" ]] && git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  if [[ -n "$branch" ]]; then
    dirty=""
    if [[ -n "$(git -C "$cwd" --no-optional-locks status --porcelain --ignore-submodules 2>/dev/null || true)" ]]; then
      dirty=" [!]"
    fi
    git_segment="$branch$dirty"
  fi
fi

# always rendered, always in K: one decimal below 100K (0.4K, 37.5K), whole K above (142K)
[[ "$used_tokens" =~ ^[0-9]+$ ]] || used_tokens=0
if (( used_tokens < 100000 )); then
  tenths=$(( (used_tokens + 50) / 100 ))
  ctx_segment="ctx $(( tenths / 10 )).$(( tenths % 10 ))K"
else
  ctx_segment="ctx $(( (used_tokens + 500) / 1000 ))K"
fi

out=""
add_segment() {
  local seg="$1"
  if [[ -z "$seg" ]]; then
    return 0
  fi
  if [[ -z "$out" ]]; then
    out="$seg"
  else
    out="$out │ $seg"
  fi
}

add_segment "$model_name"

cwd_git="$display_cwd"
if [[ -n "$git_segment" ]]; then
  cwd_git="$display_cwd  $git_segment"
fi
add_segment "$cwd_git"

add_segment "$ctx_segment"
add_segment "$version"

printf '%s' "$out"
