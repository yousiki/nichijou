#!/usr/bin/env bash
#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix jq curl

set -euo pipefail

local_dir="$(cd "$(dirname "$0")" && pwd)"
sha256_dir="$local_dir/sha256"
version_dir="$local_dir/version"

declare -A platforms=(
  [linux-x64]="linux-x64"
  [linux-arm64]="linux-arm64"
  [linux-armhf]="linux-armhf"
  [darwin]="darwin"
  [darwin-arm64]="darwin-arm64"
)

mkdir -p "$sha256_dir" "$version_dir"

# Fetch latest version for each platform
declare -A latest_versions
for plat in "${!platforms[@]}"; do
  echo "Fetching latest version for $plat..."
  api_url="https://update.code.visualstudio.com/api/update/${platforms[$plat]}/insider/latest"
  latest_versions[$plat]=$(curl -sSfL "$api_url" | jq -r .name)
  if [[ -z ${latest_versions[$plat]} ]]; then
    echo "Failed to fetch latest version for $plat"
    exit 1
  fi
  echo "Latest version for $plat: ${latest_versions[$plat]}"
done

# Read current version for each platform
declare -A current_versions
for plat in "${!platforms[@]}"; do
  version_file="$version_dir/$plat"
  if [[ -f $version_file ]]; then
    echo "Reading current version for $plat from $version_file..."
    current_versions[$plat]=$(tr -d '[:space:]' <"$version_file")
    if [[ -z ${current_versions[$plat]} ]]; then
      echo "Failed to read current version for $plat"
      exit 1
    fi
    echo "Current version for $plat: ${current_versions[$plat]}"
  else
    echo "No current version file found for $plat."
    current_versions[$plat]=""
  fi
done

# Check if all platforms are up to date
all_up_to_date=true
for plat in "${!platforms[@]}"; do
  if [[ ${latest_versions[$plat]} != "${current_versions[$plat]}" ]]; then
    all_up_to_date=false
    break
  fi
done

if $all_up_to_date; then
  echo "Already up to date:"
  for plat in "${!platforms[@]}"; do
    echo "  $plat: ${latest_versions[$plat]}"
  done
  exit 0
fi

# Update version and sha256 for each platform
for plat in "${!platforms[@]}"; do
  latest_version="${latest_versions[$plat]}"
  version_file="$version_dir/$plat"
  echo "$latest_version" >"$version_file"
  url="https://update.code.visualstudio.com/${latest_version}/${plat}/insider"
  sha256=$(nix-prefetch-url --unpack --name code-insiders "$url")
  echo "sha256:$sha256" >"$sha256_dir/$plat"
  echo "$plat updated: version=$latest_version sha256=$sha256"
done

echo "Update complete."
