#!/bin/bash
set -e

REPO_URL="git@github.com:cardoso-neto/personal-ai-infra.git"
TMP_DIR=$(mktemp -d)

git clone -q "$REPO_URL" "$TMP_DIR"
cp -r "$TMP_DIR/skills" ./

rm -rf "$TMP_DIR"
