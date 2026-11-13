#!/usr/bin/env bash
# Copies the plugin into Spell-Cost-Tracker/, leaving out the tests.
#
#   ./build.sh           dev build, plugin.json as it is in the repo
#   ./build.sh release   release build, without console commands, depends on the published gepl plugin.
#                        Also zipped into Spell-Cost-Tracker.zip, ready to upload
#
# To also copy dev builds into your game's dev_plugins folder, create
# build.local.sh (gitignored) with e.g.:
#
#   dev_plugins_dir="$HOME/path/to/RuneScape-BETA/dev_plugins"
set -euo pipefail

cd "$(dirname "$0")"

dev_plugins_dir=""
if [[ -f build.local.sh ]]; then
    source build.local.sh
fi

out_dir="Spell-Cost-Tracker"
build_type="${1:-dev}"

# The dev build uses a locally installed gepl; the release build uses the published one.
release_gepl_id=6414886

if [[ "$build_type" != "dev" && "$build_type" != "release" ]]; then
    echo "Unknown build type '$build_type', expected 'dev' or 'release'" >&2
    exit 1
fi

rm -rf "$out_dir"
mkdir -p "$out_dir"
cp -r main.lua plugin.json src "$out_dir/"

if [[ "$build_type" == "release" ]]; then
    # Console commands (like granting permissions while developing) aren't
    # allowed in published plugins.
    find "$out_dir" -name "*.lua" -exec sed -i '/^[[:space:]]*ExecuteConsoleCommand(/d' {} +
    if grep -rq "ExecuteConsoleCommand" "$out_dir" --include="*.lua"; then
        echo "Could not remove every ExecuteConsoleCommand from $out_dir" >&2
        exit 1
    fi
    sed -i -E "s/\"gepl\": *\"[^\"]*\"/\"gepl\": $release_gepl_id/" "$out_dir/plugin.json"
    if ! grep -q "\"gepl\": $release_gepl_id" "$out_dir/plugin.json"; then
        echo "Could not set the gepl dependency in $out_dir/plugin.json" >&2
        exit 1
    fi
fi

echo "Built $out_dir ($build_type)"

if [[ "$build_type" == "release" ]]; then
    if ! command -v zip > /dev/null; then
        echo "zip is not installed, so $out_dir was not zipped" >&2
        exit 1
    fi
    zip_file="$out_dir.zip"
    # zip adds to an existing archive, which would keep files that have since been removed.
    rm -f "$zip_file"
    zip -qr "$zip_file" "$out_dir"
    echo "Zipped to $zip_file"
fi

if [[ "$build_type" == "dev" && -n "$dev_plugins_dir" ]]; then
    if [[ ! -d "$dev_plugins_dir" ]]; then
        echo "dev_plugins folder not found: $dev_plugins_dir" >&2
        exit 1
    fi
    rm -rf "${dev_plugins_dir:?}/$out_dir"
    cp -r "$out_dir" "$dev_plugins_dir/"
    echo "Copied to $dev_plugins_dir/$out_dir"
fi
