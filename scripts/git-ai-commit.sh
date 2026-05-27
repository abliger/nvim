#!/bin/bash
set -euo pipefail

# ============================================================
# git-ai-commit.sh
# 根据 git diff 生成 conventional commit message
# 使用 curl + jq 实现，支持 ollama (本地) 和 openai (远程)
# ============================================================

PROVIDER="${GIT_AI_PROVIDER:-openai}"
MODEL="${GIT_AI_MODEL:-}"
API_KEY="${OPENAI_API_KEY:-}"
API_BASE="${OPENAI_API_BASE:-https://api.openai.com/v1}"
OLLAMA_URL="${GIT_AI_OLLAMA_URL:-http://localhost:11434}"

# 读取 stdin（即 prompt）
PROMPT=$(cat)

# 加载同目录下的系统提示词
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROMPT_FILE="${SCRIPT_DIR}/git-ai-prompt.txt"
if [ -f "$PROMPT_FILE" ]; then
  SYSTEM_MSG=$(cat "$PROMPT_FILE")
else
  echo "Error: prompt file not found: $PROMPT_FILE" >&2
  exit 1
fi

# 检查依赖（kimi 模式下不需要 curl/jq）
if [ "$PROVIDER" != "kimi" ]; then
  if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required" >&2
    exit 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required (install: brew install jq)" >&2
    exit 1
  fi
fi

# --------------------------------------------------------------
# Ollama 调用
# --------------------------------------------------------------
call_ollama() {
  local target_model="${MODEL:-llama3}"
  local url="${OLLAMA_URL}/api/chat"

  local body
  body=$(jq -n \
    --arg model "$target_model" \
    --arg system "$SYSTEM_MSG" \
    --arg user "$PROMPT" \
    '{
      model: $model,
      messages: [
        {role: "system", content: $system},
        {role: "user", content: $user}
      ],
      stream: false
    }')

  local response
  response=$(curl -s -L "$url" \
    -H "Content-Type: application/json" \
    -d "$body")

  local error_msg
  error_msg=$(echo "$response" | jq -r '.error // empty')
  if [ -n "$error_msg" ]; then
    echo "Ollama error: $error_msg" >&2
    exit 1
  fi

  echo "$response" | jq -r '.message.content // empty'
}

# --------------------------------------------------------------
# OpenAI 兼容调用
# --------------------------------------------------------------
call_openai() {
  local target_model="${MODEL:-gpt-3.5-turbo}"
  local url="${API_BASE}/chat/completions"

  if [ -z "$API_KEY" ]; then
    echo "Error: OPENAI_API_KEY is not set" >&2
    exit 1
  fi

  local body
  body=$(jq -n \
    --arg model "$target_model" \
    --arg system "$SYSTEM_MSG" \
    --arg user "$PROMPT" \
    '{
      model: $model,
      messages: [
        {role: "system", content: $system},
        {role: "user", content: $user}
      ],
      temperature: 0.3,
      max_tokens: 300
    }')

  local response
  response=$(curl -s -L "$url" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${API_KEY}" \
    -d "$body")

  local error_msg
  error_msg=$(echo "$response" | jq -r '.error.message // .error // empty')
  if [ -n "$error_msg" ]; then
    echo "API error: $error_msg" >&2
    exit 1
  fi

  echo "$response" | jq -r '.choices[0].message.content // empty'
}

# --------------------------------------------------------------
# Kimi CLI 调用
# --------------------------------------------------------------
call_kimi() {
  if ! command -v kimi >/dev/null 2>&1; then
    echo "Error: kimi-cli is required (install: https://www.kimi.com/code)" >&2
    exit 1
  fi

  # 使用临时文件传递 prompt，避免 stdin 行为不确定
  local tmpfile
  tmpfile=$(mktemp)
  printf '%s\n\n%s' "$SYSTEM_MSG" "$PROMPT" > "$tmpfile"
  kimi --quiet -p "$(cat "$tmpfile")"
  local exit_code=$?
  rm -f "$tmpfile"
  return $exit_code
}

# --------------------------------------------------------------
# 主逻辑
# --------------------------------------------------------------
case "$PROVIDER" in
  ollama)
    call_ollama
    ;;
  kimi)
    call_kimi
    ;;
  openai|*)
    call_openai
    ;;
esac
