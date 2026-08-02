{
  lib,
  writeShellApplication,
  curl,
  jq,
  coreutils,
  file,
}:
writeShellApplication {
  name = "grok-imagine";
  runtimeInputs = [
    curl
    jq
    coreutils
    file
  ];
  text = ''
    set -euo pipefail

    usage() {
      cat <<'EOF'
    grok-imagine — Grok Imagine image generate / edit via xAI API

    Usage:
      grok-imagine [options] "prompt"
      grok-imagine [options] --edit path/to/image.png "edit prompt"

    Options:
      -o, --out PATH       Output file (default: ./grok-imagine-<ts>.jpg)
      -n, --count N        Number of images 1-10 (default: 1)
      -r, --ratio RATIO    Aspect ratio (1:1, 16:9, 9:16, 4:3, 3:4, 3:2, 2:3, 2:1, 1:2, auto, ...)
      -R, --res RES        Resolution: 1k | 2k (default: 1k)
      -m, --model NAME     Model (default: grok-imagine-image-quality)
      --edit PATH          Edit mode; source image path or https URL
      -h, --help           Show help

    Auth (first match wins):
      $XAI_API_KEY
      $GROK_API_KEY
      ~/.pi/agent/configs/.env  (XAI_API_KEY=... or GROK_API_KEY=...)

    Examples:
      grok-imagine "neon Tokyo alley in rain, cinematic"
      grok-imagine -r 16:9 -R 2k -o hero.jpg "wide mountain sunrise"
      grok-imagine --edit photo.png "make it pencil sketch"
    EOF
    }

    load_key() {
      if [ -n "''${XAI_API_KEY:-}" ]; then
        printf '%s' "$XAI_API_KEY"
        return 0
      fi
      if [ -n "''${GROK_API_KEY:-}" ]; then
        printf '%s' "$GROK_API_KEY"
        return 0
      fi
      local envf="$HOME/.pi/agent/configs/.env"
      if [ -f "$envf" ]; then
        local line
        line="$(grep -E '^(XAI_API_KEY|GROK_API_KEY)=' "$envf" | tail -n1 || true)"
        if [ -n "$line" ]; then
          local key="''${line#*=}"
          key="''${key%\"}"
          key="''${key#\"}"
          key="''${key%\'}"
          key="''${key#\'}"
          printf '%s' "$key"
          return 0
        fi
      fi
      return 1
    }

    mime_of() {
      local p="$1"
      case "''${p,,}" in
        *.png) printf 'image/png' ;;
        *.jpg|*.jpeg) printf 'image/jpeg' ;;
        *.webp) printf 'image/webp' ;;
        *.gif) printf 'image/gif' ;;
        *) file --brief --mime-type "$p" 2>/dev/null || printf 'application/octet-stream' ;;
      esac
    }

    OUT=""
    COUNT=1
    RATIO=""
    RES="1k"
    MODEL="grok-imagine-image-quality"
    EDIT=""
    PROMPT=""

    while [ "$#" -gt 0 ]; do
      case "$1" in
        -h|--help) usage; exit 0 ;;
        -o|--out) OUT="''${2:-}"; shift 2 ;;
        -n|--count) COUNT="''${2:-}"; shift 2 ;;
        -r|--ratio) RATIO="''${2:-}"; shift 2 ;;
        -R|--res) RES="''${2:-}"; shift 2 ;;
        -m|--model) MODEL="''${2:-}"; shift 2 ;;
        --edit) EDIT="''${2:-}"; shift 2 ;;
        --) shift; break ;;
        -*)
          echo "unknown option: $1" >&2
          usage >&2
          exit 2
          ;;
        *)
          if [ -z "$PROMPT" ]; then PROMPT="$1"; else PROMPT="$PROMPT $1"; fi
          shift
          ;;
      esac
    done

    while [ "$#" -gt 0 ]; do
      if [ -z "$PROMPT" ]; then PROMPT="$1"; else PROMPT="$PROMPT $1"; fi
      shift
    done

    if [ -z "$PROMPT" ]; then
      usage >&2
      exit 2
    fi

    if ! KEY="$(load_key)"; then
      echo "error: no XAI_API_KEY/GROK_API_KEY. Set env or put key in ~/.pi/agent/configs/.env" >&2
      exit 1
    fi

    if [ -z "$OUT" ]; then
      OUT="grok-imagine-$(date +%Y%m%d-%H%M%S).jpg"
    fi

    TMPDIR_WORK="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR_WORK"' EXIT
    BODY="$TMPDIR_WORK/body.json"
    RESP="$TMPDIR_WORK/resp.json"

    if [ -n "$EDIT" ]; then
      local_image_json=""
      if [[ "$EDIT" == https://* || "$EDIT" == http://* ]]; then
        local_image_json="$(jq -nc --arg u "$EDIT" '{url:$u, type:"image_url"}')"
      else
        if [ ! -f "$EDIT" ]; then
          echo "error: edit image not found: $EDIT" >&2
          exit 1
        fi
        MIME="$(mime_of "$EDIT")"
        B64="$(base64 -w0 "$EDIT")"
        local_image_json="$(jq -nc --arg m "$MIME" --arg b "$B64" '{url:("data:"+$m+";base64,"+$b), type:"image_url"}')"
      fi
      jq -nc \
        --arg model "$MODEL" \
        --arg prompt "$PROMPT" \
        --argjson image "$local_image_json" \
        --arg ratio "$RATIO" \
        --arg res "$RES" \
        '
          {model:$model, prompt:$prompt, image:$image, response_format:"b64_json"}
          + (if $ratio != "" then {aspect_ratio:$ratio} else {} end)
          + (if $res != "" then {resolution:$res} else {} end)
        ' >"$BODY"
      ENDPOINT="https://api.x.ai/v1/images/edits"
    else
      jq -nc \
        --arg model "$MODEL" \
        --arg prompt "$PROMPT" \
        --argjson n "$COUNT" \
        --arg ratio "$RATIO" \
        --arg res "$RES" \
        '
          {model:$model, prompt:$prompt, n:($n|tonumber), response_format:"b64_json"}
          + (if $ratio != "" then {aspect_ratio:$ratio} else {} end)
          + (if $res != "" then {resolution:$res} else {} end)
        ' >"$BODY"
      ENDPOINT="https://api.x.ai/v1/images/generations"
    fi

    HTTP_CODE="$(
      curl -sS -o "$RESP" -w '%{http_code}' \
        -X POST "$ENDPOINT" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $KEY" \
        --data-binary @"$BODY"
    )"

    if [ "$HTTP_CODE" != "200" ]; then
      echo "error: API HTTP $HTTP_CODE" >&2
      jq -r '.' "$RESP" 2>/dev/null || cat "$RESP" >&2 || true
      exit 1
    fi

    COUNT_OUT="$(jq -r '(.data // []) | length' "$RESP")"
    if [ "$COUNT_OUT" = "0" ] || [ "$COUNT_OUT" = "null" ]; then
      echo "error: no image data in response" >&2
      jq -r '.' "$RESP" >&2 || true
      exit 1
    fi

    if [ "$COUNT_OUT" -eq 1 ]; then
      jq -r '.data[0].b64_json' "$RESP" | base64 -d >"$OUT"
      echo "$OUT"
    else
      base="''${OUT%.*}"
      ext="''${OUT##*.}"
      if [ "$base" = "$OUT" ]; then ext="jpg"; base="$OUT"; fi
      i=0
      while [ "$i" -lt "$COUNT_OUT" ]; do
        dest="''${base}-$((i + 1)).''${ext}"
        jq -r --argjson i "$i" '.data[$i].b64_json' "$RESP" | base64 -d >"$dest"
        echo "$dest"
        i=$((i + 1))
      done
    fi
  '';
  meta = {
    description = "Generate or edit images with xAI Grok Imagine";
    license = lib.licenses.mit;
  };
}
