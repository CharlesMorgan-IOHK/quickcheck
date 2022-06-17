#!/usr/bin/env bash

set -euo pipefail

trap '(kill $pid || true); exit' INT TERM QUIT

echo $$
sleep 3

nix-shell --run './scripts/cardano-node.sh' &
pid=$!

echo $pid
wait $pid
