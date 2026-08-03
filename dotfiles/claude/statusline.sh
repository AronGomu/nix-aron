#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"

json_line="$(jq -r '
  [
    (.model.display_name // ""),
    (.workspace.current_dir // .cwd // ""),
    (.version // ""),
    (.context_window.used_percentage // "")
  ] | @tsv
' <<<"$input" 2>/dev/null || true)"

IFS=$'\t' read -r model_name cwd version used_pct <<<"${json_line:-}"

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

ctx_segment=""
if [[ -n "$used_pct" && "$used_pct" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  ctx_segment="ctx $(printf '%.0f' "$used_pct")%"
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
