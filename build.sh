#!/bin/sh
# Usage: sh build.sh [--tag NAME] [podman build options...]
# Pass --build-arg BASE=debian to build on debian instead of the
# official podman image.
tag=claude
n=$#
while test $n -gt 0; do
    arg=$1; shift; n=$((n - 1))
    case $arg in
    --tag|-t)
        if test $n -eq 0; then
            echo "$arg needs a value" >&2
            exit 1
        fi
        tag=$1; shift; n=$((n - 1)) ;;
    --tag=*) tag=${arg#--tag=} ;;
    *) set -- "$@" "$arg" ;;
    esac
done

exec podman build \
    --build-arg CLAUDE_VERSION="$(curl -fsSL https://downloads.claude.ai/claude-code-releases/stable)" \
    --tag "$tag" "$@" .
