#!/bin/bash
cd "$(dirname "$0")"
source .venv/bin/activate
exec python xano_mcp_sdk.py "$@"
