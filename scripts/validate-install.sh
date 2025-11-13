#!/bin/bash
# Quick dependency check
set -euo pipefail

echo "Checking docker..."
if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found"
  exit 1
fi

echo "Checking docker compose plugin..."
if ! docker compose version >/dev/null 2>&1; then
  echo "docker compose plugin not found"
  exit 2
fi

echo "[ALL CHECKS PASSED]"
