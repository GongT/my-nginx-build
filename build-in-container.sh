#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit extglob nullglob globstar lastpipe shift_verbose

readonly __dirname="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
cd "$__dirname"

export TMPDIR="${__dirname}/.tmp"
mkdir -p "$TMPDIR"

if [[ " $* " == *"--no-build-container"* ]] && podman image inspect "nginx-build-base:latest" &>/dev/null; then
	printf "\e[48;5;11m- Skipping build container\e[0m\n"
else
	printf "\e[48;5;10m- Updating build container\e[0m\n"
	podman build \
		--network=host \
		-t nginx-build-base:latest \
		.
	podman image prune -f || true
fi

source ./builder/tools.sh

NGX_SRC_PATH=()
NGX_SRC_REPO=()
NGX_SRC_BRANCH=()

source ./builder/source-registry.sh

for i in "${!NGX_SRC_PATH[@]}"; do
	SOURCE_DIR="./storage/${NGX_SRC_PATH[$i]}"
	REPO_URL="https://github.com/${NGX_SRC_REPO[$i]}"
	BRANCH="${NGX_SRC_BRANCH[$i]}"
	printf "\e[48;5;14m- clone %s[%s] to %s\e[0m\n" "$REPO_URL" "$BRANCH" "$SOURCE_DIR"
	if outdated "${SOURCE_DIR}/timestamp"; then
		clone_or_update_git_repo_bare "$SOURCE_DIR" "$REPO_URL" "$BRANCH"
	else
		echo "Repository is up to date."
	fi
	touch "${SOURCE_DIR}/timestamp"
done

mkdir -p cache storage dist

printf "\e[48;5;10m- Run build container\e[0m\n"

podman container run --rm -it \
	"--network=host" \
	"--volume=${__dirname}/cache:/var/cache/ccache" \
	"--volume=${__dirname}/storage:/data/storage:ro" \
	"--volume=${__dirname}/dist:/data/dist" \
	"--name=nginx-builder" \
	nginx-build-base:latest
