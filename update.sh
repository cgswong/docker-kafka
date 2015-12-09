#!/usr/bin/env bash
set -e

pkg=${BASH_SOURCE##*/}
pkg_root=$(dirname "${BASH_SOURCE}")

# Source common script
source "${pkg_root}/common.sh"

VERSIONS=${VERSIONS:-"$@"}
if [ ! -z "$VERSIONS" ]; then
  versions=( "$VERSIONS" )
else
  versions=( ?.?.?.? )
fi
versions=( "${versions[@]%/}" )
versions=( $(printf '%s\n' "${versions[@]}"|sort -V) )

dlVersions=$(curl -sSL 'http://mirrors.ibiblio.org/apache/kafka' | sed -rn 's!.*?="([0-9]+\.[0-9]+\.[0-9]+\.[0-9]).*!\1!gp' | sort -V | uniq)
for version in "${versions[@]}"; do
  echo "${yellow}Updating version: ${version}${reset}"
  cp kafka.sh "${version}/"
  sed -e 's/%%VERSION%%/'"$version"'/' < Dockerfile.tpl > "$version/Dockerfile"
done
echo "${green}Complete${reset}"
