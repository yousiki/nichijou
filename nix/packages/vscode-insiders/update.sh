#!/usr/bin/env bash
#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix

fetchsha256() {
  # this function fetches the sha256 of the vscode insiders tarball
  # it takes one argument, the architecture

  if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <arch>"
    exit 1
  fi

  # arch is the first argument
  arch=$1

  # arch should be one of linux-x64, linux-arm64
  if [[ 
    $arch != "linux-x64" &&
    $arch != "linux-arm64" &&
    $arch != "linux-armhf" &&
    $arch != "darwin" &&
    $arch != "darwin-arm64" ]]; then
    echo "Invalid architecture: $arch"
    exit 1
  fi

  # fetch the sha256 via nix-prefetch-url
  sha256=$(
    nix-prefetch-url --unpack --name code-insiders \
      "https://code.visualstudio.com/sha/download?build=insider&os=$arch"
  )

  echo "$arch: $sha256"

  local_dir=$(dirname "$0")

  # create the directory if it doesn't exist
  mkdir -p "$local_dir/sha256"

  # save the results to file
  echo "sha256:$sha256" >"$local_dir/sha256/$arch"
}

fetchsha256 linux-x64
fetchsha256 linux-arm64
fetchsha256 linux-armhf
fetchsha256 darwin
fetchsha256 darwin-arm64
