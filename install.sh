#!/bin/bash
git init --initial-branch=master
git remote add upstream git@github.com:cardoso-neto/personal-ai-infra.git
git pull upstream master

# TODO: add logic to detect if a claude.md exists and idk