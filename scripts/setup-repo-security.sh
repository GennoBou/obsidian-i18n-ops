#!/usr/bin/env bash
#
# Obsidian プラグイン翻訳フォークリポジトリのセキュリティ＆ブランチ保護を自動設定するスクリプト。
#
# 使い方:
#   ./scripts/setup-repo-security.sh [owner/repo]
#

set -euo pipefail

REPO="${1:-}"

if [ -z "$REPO" ]; then
    REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)
    if [ -z "$REPO" ]; then
        REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
        if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+/[^/.]+)(\.git)?$ ]]; then
            REPO="${BASH_REMATCH[1]}"
        fi
    fi
fi

if [ -z "$REPO" ]; then
    echo "[ERROR] 対象の GitHub リポジトリを特定できませんでした。引数に 'owner/repo' を指定してください。" >&2
    exit 1
fi

echo "=========================================="
echo "リポジトリ セキュリティ設定の自動構成"
echo "対象リポジトリ: $REPO"
echo "=========================================="

echo ""
echo "[1/2] GitHub Actions の書き込み権限 (Workflow permissions: write) を設定中..."
if gh api -X PUT "repos/$REPO/actions/permissions/workflow" -f default_workflow_permissions=write --silent 2>/dev/null; then
    echo "✓ GitHub Actions の書き込み権限を 'Read and write' に設定しました。"
else
    echo "[WARN] GitHub Actions 権限の設定に失敗しました（権限不足の可能性があります）。" >&2
fi

echo ""
echo "[2/2] ブランチ保護ルールセット (Ruleset: Protect master) を設定中..."

RULESET_PAYLOAD=$(cat << 'EOF'
{
  "name": "Protect master",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": [
        "~DEFAULT_BRANCH"
      ],
      "exclude": []
    }
  },
  "bypass_actors": [
    {
      "actor_id": 5,
      "actor_type": "RepositoryRole",
      "bypass_mode": "always"
    }
  ],
  "rules": [
    {
      "type": "deletion"
    },
    {
      "type": "non_fast_forward"
    }
  ]
}
EOF
)

EXISTING_ID=$(gh api "repos/$REPO/rulesets" --jq '.[] | select(.name == "Protect master") | .id' 2>/dev/null || true)

if [ -n "$EXISTING_ID" ]; then
    echo "既存のルールセット 'Protect master' (ID: $EXISTING_ID) を更新中..."
    echo "$RULESET_PAYLOAD" | gh api -X PUT "repos/$REPO/rulesets/$EXISTING_ID" --input - --silent
    echo "✓ ルールセット 'Protect master' を更新しました。"
else
    echo "新規ルールセット 'Protect master' を作成中..."
    echo "$RULESET_PAYLOAD" | gh api -X POST "repos/$REPO/rulesets" --input - --silent
    echo "✓ ルールセット 'Protect master' を作成しました。"
fi

echo ""
echo "[3/3] リポジトリ Description（説明文）の確認・更新中..."
REPO_JSON=$(gh api "repos/$REPO" 2>/dev/null || true)
if [ -n "$REPO_JSON" ]; then
    CURRENT_DESC=$(echo "$REPO_JSON" | jq -r '.description // ""')
    PARENT_DESC=$(echo "$REPO_JSON" | jq -r '.parent.description // ""')
    I18N_SUFFIX=" - with i18n support (+ Japanese)"

    if [ -n "$PARENT_DESC" ] && [ "$PARENT_DESC" != "null" ]; then
        EXPECTED_DESC="${PARENT_DESC}${I18N_SUFFIX}"
        if [ "$CURRENT_DESC" != "$EXPECTED_DESC" ]; then
            gh repo edit "$REPO" --description "$EXPECTED_DESC"
            echo "✓ リポジトリ Description を更新しました: $EXPECTED_DESC"
        else
            echo "✓ リポジトリ Description は既に最新です。"
        fi
    elif [ -n "$CURRENT_DESC" ] && [[ "$CURRENT_DESC" != *"$I18N_SUFFIX" ]]; then
        NEW_DESC="${CURRENT_DESC}${I18N_SUFFIX}"
        gh repo edit "$REPO" --description "$NEW_DESC"
        echo "✓ リポジトリ Description を更新しました: $NEW_DESC"
    fi
fi

echo ""
echo "=========================================="
echo "設定が完了しました。"
echo "・ブランチの誤削除防止: 有効"
echo "・Force push (強制上書き) 防止: 有効"
echo "・GitHub Actions による自動 push (upstream-sync): 許可 (バイパス)"
echo "・リポジトリ Description (i18n 規約): 適用済み"
echo "=========================================="
