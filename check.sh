#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2026 Mohammed Maruff (Esan Maruff) <esan@etamil.in>
#
# Runs `etamil --check` on every file matching INPUT_CHECK. Nothing is executed.
set -uo pipefail
shopt -s globstar nullglob
failed=0 count=0
for pattern in $INPUT_CHECK; do
    for file in $pattern; do
        [ -f "$file" ] || continue
        count=$((count + 1))
        if ! etamil --check "$file"; then
            echo "::error file=$file::etamil --check failed"
            failed=$((failed + 1))
        fi
    done
done
[ "$count" -gt 0 ] || { echo "::error::no files match '$INPUT_CHECK'"; exit 1; }
echo "checked $count file(s), $failed with errors"
[ "$failed" -eq 0 ]
