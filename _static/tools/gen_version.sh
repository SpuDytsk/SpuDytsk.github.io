#!/bin/bash

BUILD_DATE=$1
COMMIT_HASH=$2
COMMIT_UNIXTIME=$(git show -s --format=%ct $COMMIT_HASH)
DESCRIBE_FLAGS=
git describe -h | grep -qF -- '--broken' && DESCRIBE_FLAGS="--broken"

cat <<EOF
{
  "last_commit": {
    "date": "$(date -d @$COMMIT_UNIXTIME -u +'%Y-%m-%d %H:%M:%S UTC')",
    "hash": "$COMMIT_HASH",
    "describe": "$(git describe --long --dirty $DESCRIBE_FLAGS --tags)"
  },
  "build": {
    "date": "$BUILD_DATE",
    "clean repo": $(git diff --quiet && echo 'true' || echo 'false'),
    "sphinx version": "$(${SPHINXBUILD:-sphinx-build} --version | tr -d '\r\n')",
    "machine": "$(hostname)"
  },
  "note": "${NOTE}"
}
EOF
