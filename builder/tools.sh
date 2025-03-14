#!/usr/bin/env bash

function clone_or_update_git_repo_bare() {
	local path="$1"
	local repo="$2"
	local branch="${3:-master}"
	local depth="${4:-5}"

	if [[ -d $path ]]; then
		echo "Updating existing repository..."
		(
			cd "$path"
			x git fetch --depth="$depth"
		)
	else
		echo "Cloning new repository..."
		x git clone --bare --depth="$depth" --branch="$branch" "$repo" "$path"
	fi
}

function outdated() {
	local file="$1"
	local expires="${2:-3600}"
	local now=$(date +%s)
	local file_time=$(stat -c %Y "$file" 2>/dev/null || echo 0)
	local diff=$((now - file_time))
	[[ $diff -gt $expires ]]
}

function extract_git_bare_repo() {
	local src="$1"``
	local dest="$2"
	local branch="${3:-master}"

	git --git-dir="$src" archive --format=tar --prefix="$dest/" "$branch" | tar -xf -
	# x git clone --recurse-submodules --shallow-submodules --depth=1 "--branch=$branch" "file://$src" "$dest"
}

function x() {
	echo "$@" >&2
	"$@"
}
