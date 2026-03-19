#!/bin/bash
# git-worktree-add.sh
# モノレポ用 git worktree 作成スクリプト
# sparse-checkout でスコープを絞ったworktreeをfeatureブランチとして作成する
#
# Usage:
#   ./git-worktree-add.sh -b <branch> -s <sparse_patterns> [-w <worktree_path>]
#
# Options:
#   -b  ブランチ名（必須）。リモートに存在すればそこから、なければ origin デフォルトブランチ から作成
#   -s  sparse-checkout のパターン（必須）。スペース区切りで複数指定可能
#   -w  worktreeのパス（省略時: ../worktree/<branch>）
#
# Examples:
#   ./git-worktree-add.sh -b feature/api-v2 -s "packages/service-b"
#   ./git-worktree-add.sh -b feature/api-v2 -s "packages/service-a packages/service-b"
#   ./git-worktree-add.sh -b feature/api-v2 -s "packages/service-b" -w ../custom-path

while getopts "w:b:s:" opt; do
  case $opt in
    w) WORKTREE_PATH="$OPTARG" ;;
    b) BRANCH="$OPTARG" ;;
    s) SPARSE_PATTERNS="$OPTARG" ;;
  esac
done

WORKTREE_PATH="${WORKTREE_PATH:-../worktree/${BRANCH//\//-}}"
readonly DEFAULT_BRANCH=origin/main

git config extensions.worktreeConfig true
git fetch origin

if git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
  # リモートに既存 → それをベースにfeatureブランチ作成
  git worktree add --no-checkout -b "$BRANCH" "$WORKTREE_PATH" "origin/$BRANCH"
else
  # なければmasterから新規作成
  git worktree add --no-checkout -b "$BRANCH" "$WORKTREE_PATH" "$DEFAULT_BRANCH"
  git -C "$WORKTREE_PATH" branch --unset-upstream
fi

git -C "$WORKTREE_PATH" sparse-checkout init --cone
git -C "$WORKTREE_PATH" sparse-checkout set $SPARSE_PATTERNS
git -C "$WORKTREE_PATH" checkout

echo "Worktree: $WORKTREE_PATH"
echo "Branch:   $BRANCH"
echo "Scope:    $SPARSE_PATTERNS"
