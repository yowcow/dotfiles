#!/usr/bin/env bash
# Build throwaway real git repositories for the offline suite. Sourced by test
# files whose script under test shells out to git; harness.sh must be sourced
# first, since everything here lives under $HARNESS_TMP and is removed with it.
#
# git is NOT stubbed. The scripts under test lean on real git behaviour --
# FETCH_HEAD being overwritten per fetch, `git merge-tree` exiting 1 for both a
# genuine conflict and an unresolvable ref -- and a stub would encode whatever
# the test author believed about that rather than what git does.
#
# The identity a repository presents is carried by its *path*:
# check-pr-state.sh reduces a remote URL to its last two segments, so a bare
# repo at .../acme/widgets.git reads as `acme/widgets` while still being a
# local directory that `git fetch` can reach without a network.
#
# The environment below is set once, at source time, and deliberately cuts the
# developer's own git configuration out of the picture. `url.<base>.insteadOf`
# in a personal ~/.gitconfig can rewrite a local path into a network URL, which
# would put this suite on the network by way of a setting no test can see; and
# init.defaultBranch, commit hooks and templates would otherwise make results
# differ per machine. GIT_TERMINAL_PROMPT=0 keeps a misconfigured case failing
# instead of blocking on a credential prompt.

export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_SYSTEM=/dev/null
export GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0
export GIT_AUTHOR_NAME='Test Author'
export GIT_AUTHOR_EMAIL='author@example.invalid'
export GIT_COMMITTER_NAME='Test Committer'
export GIT_COMMITTER_EMAIL='committer@example.invalid'

# Fixed timestamps, advanced one minute per commit, so commit order is
# deterministic and does not depend on how fast the suite runs.
GITREPO_CLOCK=1700000000

gitrepo_stamp() {
  GITREPO_CLOCK=$((GITREPO_CLOCK + 60))
  printf '%s +0000\n' "$GITREPO_CLOCK"
}

# git_repo_scratch <name> -> prints a fresh empty directory under $HARNESS_TMP
git_repo_scratch() {
  local dir="${HARNESS_TMP}/repos/$1"
  rm -rf "$dir"
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}

# git_repo_bare <owner> <repo> -> prints the path of a new bare repo whose last
# two path segments are <owner>/<repo>.git
git_repo_bare() {
  local dir="${HARNESS_TMP}/remotes/$1/$2.git"
  rm -rf "$dir"
  mkdir -p "$dir"
  git init -q --bare "$dir"
  printf '%s\n' "$dir"
}

# git_repo_init <dir> <initial-branch>
git_repo_init() {
  local dir="$1" branch="$2"
  mkdir -p "$dir"
  git init -q "$dir"
  # symbolic-ref rather than `git init -b`, which needs git 2.28, and rather
  # than init.defaultBranch, which the config isolation above rules out.
  git -C "$dir" symbolic-ref HEAD "refs/heads/${branch}"
}

# git_repo_commit <dir> <file> <content> <message>   content goes through %b
git_repo_commit() {
  local dir="$1" file="$2" content="$3" message="$4" stamp
  mkdir -p "$(dirname -- "${dir}/${file}")"
  printf '%b' "$content" >"${dir}/${file}"
  git -C "$dir" add -- "$file"
  stamp="$(gitrepo_stamp)"
  GIT_AUTHOR_DATE="$stamp" GIT_COMMITTER_DATE="$stamp" \
    git -C "$dir" commit -q -m "$message"
}

# git_repo_checkout <dir> <branch> [<start-point>]
git_repo_checkout() {
  local dir="$1" branch="$2"
  if [ "$#" -ge 3 ]; then
    git -C "$dir" checkout -q -b "$branch" "$3"
  else
    git -C "$dir" checkout -q "$branch"
  fi
}

# git_repo_remote <dir> <name> <url>
git_repo_remote() {
  local dir="$1" name="$2" url="$3"
  git -C "$dir" remote remove "$name" 2>/dev/null || true
  git -C "$dir" remote add "$name" "$url"
}

# git_repo_push <dir> <remote> <refspec>...
git_repo_push() {
  local dir="$1" remote="$2"
  shift 2
  git -C "$dir" push -q "$remote" "$@"
}
