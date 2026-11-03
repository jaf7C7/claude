#!/bin/sh
exec podman build \
    --build-arg CLAUDE_VERSION=$(curl -fsSL https://downloads.claude.ai/claude-code-releases/stable) \
    --tag claude "$@" .
