#!/usr/bin/env bash

set -Eeuo pipefail

if ! command -v gemini >/dev/null 2>&1; then
    npm install -g @google/gemini-cli
fi