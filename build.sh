#!/usr/bin/env bash
# Copies the plugin into Spell-Cost-Tracker/, leaving out the tests.
set -euo pipefail

cd "$(dirname "$0")"

out_dir="Spell-Cost-Tracker"

rm -rf "$out_dir"
mkdir -p "$out_dir"
cp -r main.lua plugin.json src "$out_dir/"

echo "Built $out_dir"
