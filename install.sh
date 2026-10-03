#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2026 Mohammed Maruff (Esan Maruff) <esan@etamil.in>
#
# Installs the eTamil release package for this runner and puts it on PATH.
# ETAMIL_RELEASE_BASE, if set, replaces the GitHub release URL (mirror or test).
set -euo pipefail

REPO="${ETAMIL_REPO:-Maruff/eTamil_lang}"
version="${INPUT_VERSION:-latest}"
version="${version#v}"

case "$RUNNER_OS-$RUNNER_ARCH" in
    Linux-X64)     pkg=etamil-linux-x64.tar.gz ;;
    Linux-ARM64)   pkg=etamil-linux-arm64.tar.gz ;;
    macOS-X64)     pkg=etamil-macos-x64.tar.gz ;;
    macOS-ARM64)   pkg=etamil-macos-arm64.tar.gz ;;
    Windows-X64)   pkg=etamil-windows-x64.zip ;;
    *) echo "::error::no eTamil package for $RUNNER_OS $RUNNER_ARCH"; exit 1 ;;
esac

if [ -z "${ETAMIL_RELEASE_BASE:-}" ]; then
    if [ "$version" = latest ]; then
        # The /releases/latest redirect names the tag; no API call, no rate limit.
        final="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$REPO/releases/latest")"
        version="${final##*/v}"
        [ -n "$version" ] && [ "$version" != "$final" ] || { echo "::error::could not resolve the latest release"; exit 1; }
    fi
    base="https://github.com/$REPO/releases/download/v$version"
else
    base="$ETAMIL_RELEASE_BASE"
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
echo "Installing eTamil $version ($pkg)"
curl -fsSL -o "$work/$pkg" "$base/$pkg"
curl -fsSL -o "$work/$pkg.sha256" "$base/$pkg.sha256"

expected="$(awk '{print tolower($1)}' "$work/$pkg.sha256")"
if command -v sha256sum >/dev/null; then actual="$(sha256sum "$work/$pkg" | awk '{print $1}')"
else actual="$(shasum -a 256 "$work/$pkg" | awk '{print $1}')"; fi
[ "$actual" = "$expected" ] || { echo "::error::checksum mismatch for $pkg: expected $expected, got $actual"; exit 1; }

# Windows: Git's tar is GNU tar and reads "C:" as a host, so use System32's bsdtar.
if [ "$RUNNER_OS" = Windows ]; then tar_cmd=/c/Windows/System32/tar.exe; else tar_cmd=tar; fi
"$tar_cmd" -xf "$work/$pkg" -C "$work"

# The archive unpacks to a folder named like the archive, minus its extension.
inner="${pkg%.tar.gz}"
inner="${inner%.zip}"

# Windows runners give C:\ paths; bash wants the POSIX form for mkdir, mv, dirname.
cache="${RUNNER_TOOL_CACHE:-$RUNNER_TEMP}"
if [ "$RUNNER_OS" = Windows ]; then cache="$(cygpath -u "$cache")"; fi
dest="$cache/etamil/$version"
rm -rf "$dest"
mkdir -p "$(dirname "$dest")"
mv "$work/$inner" "$dest"

if [ "$RUNNER_OS" = Windows ]; then native="$(cygpath -w "$dest")"; else native="$dest"; fi
echo "$native" >> "$GITHUB_PATH"
echo "ETAMIL_PATH=$native" >> "$GITHUB_ENV"
echo "version=$version" >> "$GITHUB_OUTPUT"

if [ "$RUNNER_OS" = Windows ]; then exe="$dest/etamil.exe"; else exe="$dest/etamil"; chmod +x "$exe"; fi
"$exe" --version
