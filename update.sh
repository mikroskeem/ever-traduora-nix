#!/usr/bin/env bash
set -euo pipefail
root="$(realpath .)"

pushd ever-traduora

pushd webapp
nix run nixpkgs#yarn2nix > "${root}/yarn-web.nix"
popd

pushd api
nix run nixpkgs#yarn2nix > "${root}/yarn-api.nix"
popd

popd
