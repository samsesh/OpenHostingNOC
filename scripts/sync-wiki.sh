#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ ! -d "${PROJECT_DIR}/.github/wiki" ]; then
    echo "Error: .github/wiki/ not found"
    exit 1
fi

WIKI_TMP=$(mktemp -d)
git clone https://github.com/samsesh/OpenHostingNOC.wiki.git "$WIKI_TMP"
cp "${PROJECT_DIR}/.github/wiki/"*.md "$WIKI_TMP/"
cp -r "${PROJECT_DIR}/.github/wiki/images" "$WIKI_TMP/" 2>/dev/null || true

cd "$WIKI_TMP"
git add -A
if git diff --cached --quiet; then
    echo "Wiki is already up to date."
else
    git commit -m "Sync wiki content from .github/wiki/"
    git push
    echo "Wiki synced successfully."
fi

rm -rf "$WIKI_TMP"
