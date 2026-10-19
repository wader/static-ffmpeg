#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

dockerfile="${1:-Dockerfile}"
dl_dir="${2:-dl-cache}"

if ! [[ -f $dockerfile ]]; then
  echo "dockerfile not found: $dockerfile" >&2
  exit 1
fi

eval "$(sed -n 's/^ARG \([A-Za-z_][A-Za-z0-9_]*=\)/\1/p' "$dockerfile")"

mkdir -p "$dl_dir"

fetch_file() {
  local url=$1 file=$dl_dir/$2 sha=$3
  if ! echo "$sha  $file" | sha256sum -c - >/dev/null 2>&1; then
    wget -O "$file.tmp" $WGET_OPTS "$url"
    echo "$sha  $file.tmp" | sha256sum -c -
    mv "$file.tmp" "$file"
  fi
}

git_clone() {
  local url=$1 dir=$dl_dir/$2 commit=$3 changes
  if ! [[ $commit =~ ^[0-9a-f]{40}$ ]]; then
    echo "not a commit for $url: $commit" >&2
    exit 1
  fi
  # explicit git dir: git -C falls back to the project repo when .git is broken
  local repo_git=(git --git-dir="$dir/.git" --work-tree="$dir")
  if ! { [[ $("${repo_git[@]}" rev-parse HEAD 2>/dev/null) == "$commit" ]] && "${repo_git[@]}" read-tree HEAD 2>/dev/null \
      && changes=$("${repo_git[@]}" status --porcelain --untracked-files=all 2>/dev/null) && [[ -z $changes ]]; }; then
    rm -rf "$dir" "$dir.tmp"
    git clone --filter=tree:0 --no-checkout "$url" "$dir.tmp"
    git -C "$dir.tmp" -c advice.detachedHead=false checkout --recurse-submodules "$commit"
    mv "$dir.tmp" "$dir"
  fi
}

while read -r prefix; do
  file_var=${prefix}_FILE url_var=${prefix}_URL sha_var=${prefix}_SHA256
  dir_var=${prefix}_DIR commit_var=${prefix}_COMMIT
  if [[ -n ${!file_var:-} ]]; then
    fetch_file "${!url_var}" "${!file_var}" "${!sha_var}"
  else
    git_clone "${!url_var}" "${!dir_var}" "${!commit_var:-}"
  fi
done < <(sed -n 's/^ARG \([A-Za-z0-9_]*\)_URL=.*/\1/p' "$dockerfile")
