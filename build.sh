#!/usr/bin/env bash
#------------------------------------------------------------------------------
# Build Hugo site for Cloudflare Workers (no root privileges required)
#------------------------------------------------------------------------------
set -euo pipefail

HUGO_VERSION="0.148.1"

# 1) 如果系统已装 Hugo，就直接用
if command -v hugo &>/dev/null; then
  echo "➡ Using existing $(hugo version)"
  hugo --gc --minify
  exit 0
fi

# 2) 否则临时下载到 $TMPDIR
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"   # linux / darwin
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *) echo "Unsupported arch: $ARCH"; exit 1 ;;
esac

echo "⬇ Downloading Hugo Extended v${HUGO_VERSION} for ${OS}-${ARCH} ..."
TMPDIR="$(mktemp -d)"
curl -sSL -o "${TMPDIR}/hugo.tar.gz" \
  "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_${OS}-${ARCH}.tar.gz"
tar -xf "${TMPDIR}/hugo.tar.gz" -C "${TMPDIR}" hugo

# 3) 用临时二进制编译站点
echo "🏗  Building site ..."
"${TMPDIR}/hugo" --gc --minify
