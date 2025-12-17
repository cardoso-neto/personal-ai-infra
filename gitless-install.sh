#!/bin/bash
set -e

REPO_URL="git@github.com:cardoso-neto/personal-ai-infra.git"
TMP_DIR=$(mktemp -d)

git clone -q "$REPO_URL" "$TMP_DIR"
cp -r "$TMP_DIR/context" ./

if [ -f "AGENTS.md" ]; then
    echo -e "\nSee @context/index.md for further instructions and context." >> AGENTS.md
else
    echo "See @context/index.md" > AGENTS.md
fi

rm -rf "$TMP_DIR"
