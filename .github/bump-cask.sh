#!/usr/bin/env bash
# Bumps a cask to the latest upstream release.
# Usage: bump-cask.sh <cask-token> github <owner/repo> <asset-name>
#        bump-cask.sh <cask-token> verfile <version-url> <download-url>
# Requires GH_TOKEN (github source) and RUNNER_TEMP.
set -euo pipefail

token=$1 source=$2
cask=Casks/$token.rb

# Upstream not being ready (asset not uploaded yet, bot challenge instead of
# the file) is retried on the next run rather than failing the job.
skip() {
  echo "::warning::$token: $1, retrying on the next run"
  exit 0
}

case $source in
  github)
    repo=$3 asset=$4
    release=$(gh release view -R "$repo" --json tagName,assets)
    tag=$(jq -r .tagName <<<"$release")
    version=${tag#v}
    url=https://github.com/$repo/releases/download/$tag/$asset
    jq -e --arg a "$asset" '.assets[] | select(.name == $a)' <<<"$release" >/dev/null ||
      skip "$tag has no $asset yet"
    ;;
  verfile)
    url=$4
    version=$(curl -fsSL --retry 3 "$3" | head -c 64 | tr -d '[:space:]') ||
      skip "version file is unavailable"
    ;;
  *)
    echo "::error::Unknown source: $source"
    exit 1
    ;;
esac

[[ $version =~ ^[0-9]+(\.[0-9]+)+$ ]] || skip "unexpected version '${version:0:32}'"

current=$(sed -n 's/^  version "\(.*\)"$/\1/p' "$cask")
if [[ $version == "$current" ]]; then
  echo "Already at $current"
  exit 0
fi

file=$RUNNER_TEMP/$token.dmg
curl -fsSL --retry 3 -o "$file" "$url" || skip "download failed"
# A disk image ends with a 512-byte trailer that starts with "koly".
[[ $(tail -c 512 "$file" | head -c 4) == koly ]] || skip "download is not a disk image"
sha=$(sha256sum "$file" | cut -d' ' -f1)

sed -i \
  -e "s/^  version \".*\"$/  version \"$version\"/" \
  -e "s/^  sha256 \".*\"$/  sha256 \"$sha\"/" \
  "$cask"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git commit -am "$token $version"
git pull --rebase
git push
