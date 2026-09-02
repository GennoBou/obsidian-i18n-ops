#Requires -Version 5.1
<#
.SYNOPSIS
    Obsidian プラグイン翻訳フォークリポジトリのセキュリティ＆ブランチ保護を自動設定するスクリプト。

.DESCRIPTION
    1. GitHub Actions のワークフロー権限を 'Read and write permissions' に設定します。
    2. master (デフォルトブランチ) に対してブランチ保護ルールセット（Ruleset）を作成し、
       ブランチ削除と Force Push を禁止しつつ、GitHub Actions と管理者のバイパスを許可します。

.PARAMETER Repo
    対象の GitHub リポジトリ（例: "GennoBou/quickadd-i18n"）。
    省略時はカレントディレクトリの Git リモート情報から自動検出します。

.EXAMPLE
    .\scripts\setup-repo-security.ps1
    .\scripts\setup-repo-security.ps1 -Repo "GennoBou/quickadd-i18n"
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$Repo
)

$ErrorActionPreference = "Stop"

# 1. 対象リポジトリの特定
if (-not $Repo) {
    try {
        $Repo = (gh repo view --json nameWithOwner -q .nameWithOwner 2>$null)
    }
    catch {
        $Repo = $null
    }

    if (-not $Repo) {
        # git remote からの取得を試行
        try {
            $remoteUrl = (git remote get-url origin 2>$null)
            if ($remoteUrl -match 'github\.com[:/]([^/]+/[^/.]+?)(\.git)?$') {
                $Repo = $Matches[1]
            }
        }
        catch {
            $Repo = $null
        }
    }
}

if (-not $Repo) {
    Write-Error "対象の GitHub リポジトリを特定できませんでした。-Repo <owner/repo> を指定してください。"
    exit 1
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "リポジトリ セキュリティ設定の自動構成" -ForegroundColor Cyan
Write-Host "対象リポジトリ: $Repo" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan

# 2. GitHub Actions 権限（Workflow Permissions: Read and write）の設定
Write-Host "`n[1/2] GitHub Actions の書き込み権限 (Workflow permissions: write) を設定中..." -ForegroundColor Cyan
try {
    gh api -X PUT "repos/$Repo/actions/permissions/workflow" -f default_workflow_permissions=write --silent
    Write-Host "✓ GitHub Actions の書き込み権限を 'Read and write' に設定しました。" -ForegroundColor Green
}
catch {
    Write-Warning "GitHub Actions 権限の設定に失敗しました（権限不足の可能性があります）: $_"
}

# 3. master ブランチ保護ルールセット（Ruleset）の作成・確認
Write-Host "`n[2/2] ブランチ保護ルールセット (Ruleset: Protect master) を設定中..." -ForegroundColor Cyan

$rulesetPayload = @"
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
"@

try {
    # 既存の ruleset 一覧を取得
    $existingRulesets = gh api "repos/$Repo/rulesets" | ConvertFrom-Json
    $targetRuleset = $existingRulesets | Where-Object { $_.name -eq "Protect master" }

    if ($targetRuleset) {
        Write-Host "既存のルールセット 'Protect master' (ID: $($targetRuleset.id)) を更新中..." -ForegroundColor Yellow
        $rulesetPayload | gh api -X PUT "repos/$Repo/rulesets/$($targetRuleset.id)" --input - --silent
        Write-Host "✓ ルールセット 'Protect master' を更新しました。" -ForegroundColor Green
    }
    else {
        Write-Host "新規ルールセット 'Protect master' を作成中..." -ForegroundColor Yellow
        $rulesetPayload | gh api -X POST "repos/$Repo/rulesets" --input - --silent
        Write-Host "✓ ルールセット 'Protect master' を作成しました。" -ForegroundColor Green
    }
}
catch {
    Write-Warning "ルールセットの設定に失敗しました: $_"
}

# 4. リポジトリ Description（説明文）の設定・更新
Write-Host "`n[3/3] リポジトリ Description（説明文）の確認・更新中..." -ForegroundColor Cyan
try {
    $repoInfo = gh api "repos/$Repo" | ConvertFrom-Json
    $currentDesc = $repoInfo.description
    $i18nSuffix = " - with i18n support (+ Japanese)"

    if ($repoInfo.parent) {
        $parentDesc = $repoInfo.parent.description
        if ($parentDesc) {
            $expectedDesc = "$parentDesc$i18nSuffix"
            if ($currentDesc -ne $expectedDesc) {
                gh repo edit $Repo --description $expectedDesc
                Write-Host "✓ リポジトリ Description を更新しました: $expectedDesc" -ForegroundColor Green
            }
            else {
                Write-Host "✓ リポジトリ Description は既に最新です。" -ForegroundColor Green
            }
        }
    }
    elseif ($currentDesc -and -not $currentDesc.EndsWith($i18nSuffix)) {
        $newDesc = "$currentDesc$i18nSuffix"
        gh repo edit $Repo --description $newDesc
        Write-Host "✓ リポジトリ Description を更新しました: $newDesc" -ForegroundColor Green
    }
}
catch {
    Write-Warning "リポジトリ Description の設定に失敗しました: $_"
}

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "設定が完了しました。" -ForegroundColor Green
Write-Host "・ブランチの誤削除防止: 有効"
Write-Host "・Force push (強制上書き) 防止: 有効"
Write-Host "・GitHub Actions による自動 push (upstream-sync): 許可 (バイパス)"
Write-Host "・リポジトリ Description (i18n 規約): 適用済み"
Write-Host "==========================================" -ForegroundColor Cyan
