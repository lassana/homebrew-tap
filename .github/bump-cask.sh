#!/usr/bin/env bash
# Bumps a cask to the latest GitHub release of its upstream repository.
# Usage: bump-cask.sh <cask-token> <owner/repo> <asset-name>
# Requires GH_TOKEN and RUNNER_TEMP.
set -euo pipefail

token=$1 upstream=$2 asset=$3
cask=Casks/$token.rb

release=$(gh release view -R "$upstream" --json tagName,assets)
tag=$(jq -r .tagName <<<"$release")
version=${tag#v}
if [[ ! $version =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
  echo "::error::Unexpected release tag: $tag"
  exit 1
fi

current=$(sed -n 's/^  version "\(.*\)"$/\1/p' "$cask")
if [[ $version == "$current" ]]; then
  echo "Already at $current"
  exit 0
fi

if ! jq -e --arg a "$asset" '.assets[] | select(.name == $a)' <<<"$release" >/dev/null; then
  echo "::notice::$tag has no $asset yet, retrying on the next run"
  exit 0
fi

curl -fsSL --retry 3 -o "$RUNNER_TEMP/$asset" \
  "https://github.com/$upstream/releases/download/$tag/$asset"
sha=$(sha256sum "$RUNNER_TEMP/$asset" | cut -d' ' -f1)

sed -i \
  -e "s/^  version \".*\"$/  version \"$version\"/" \
  -e "s/^  sha256 \".*\"$/  sha256 \"$sha\"/" \
  "$cask"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git commit -am "$token $version"
git pull --rebase
git push
