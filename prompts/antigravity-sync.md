# Antigravity 指示書: 差分同期・コンフリクト解消 & 日本語翻訳タスク

この指示書は、GitHub Actions（`upstream-sync.yml`）によって起票された同期Issue（`[i18n-sync]`）を元に、Antigravity（AIエージェント）が正確かつ安全にコンフリクトを解消、または不足している日本語訳を追加するための標準手順書です。

---

## 🎯 タスクの概要と判定

GitHub Actions から起票される Issue には以下の2種類があります。Issueのタイトルおよびラベルを確認して該当する手順を実行します。

1. **パターンA: Upstream Conflict（マージ競合解消）**
   - **Issueタイトル**: `⚠️ [i18n-sync] Upstream Conflict in i18n-core (YYYY-MM-DD)`
   - **ラベル**: `upstream-sync`, `conflict`, `antigravity-task`
   - **目的**: `i18n-core` ブランチに本家 upstream の更新を取り込み、発生したコンフリクトを解消した上でPRを作成またはリレーマージすること。

2. **パターンB: New Untranslated Keys（新規キー翻訳追加）**
   - **Issueタイトル**: `🌐 [i18n-sync] New Untranslated Keys Detected (YYYY-MM-DD)`
   - **ラベル**: `upstream-sync`, `translation-needed`, `antigravity-task`
   - **目的**: `src/locales/en.json` に新しく追加されたキーに対して、`glossary/obsidian-ja.json` を参照し `src/locales/ja.json` に自然な日本語訳を追加すること。

---

## ⛔ 絶対禁止事項（CRITICAL RULES）

- **既存フォーク設定ファイルの削除・初期化の禁止**:
  - `.github/workflows/` 内のファイル、`manifest.json`、`package.json`、`README.md`（フォーク用説明文）などを削除したり、upstream のファイルで全上書きしてはなりません。
- **Git 破壊的操作の禁止**:
  - `git reset --hard` や upstream ブランチの直接チェックアウトによるフォーク独自ファイルの破棄を行ってはなりません。
- **Raw Key（原文キー）の改変禁止**:
  - `en.json` のキー名やコード中の `t("...")` の文字列は、本家英語原文そのものです。勝手に要約したり変更してはなりません。

---

## 🛠️ パターンA: コンフリクト解消手順（Conflict Resolution）

### Step A-1: Issue と競合情報の確認
1. 対象プラグインのローカルリポジトリ（例: `workspace/<plugin-name>`）に移動。
2. GitHub Issue を確認し、競合ファイル一覧と Upstream Commit を把握します：
   ```powershell
   gh issue view <issue-number>
   ```

### Step A-2: 作業ブランチの作成とマージ試行
1. 最新のリモート情報を取得：
   ```powershell
   git fetch origin
   git fetch upstream
   ```
2. `i18n-core` ブランチを起点に作業ブランチを作成：
   ```powershell
   git checkout -B fix/upstream-sync-<YYYYMMDD> origin/i18n-core
   ```
3. upstream の対象ブランチ（通常は `upstream/master` または `upstream/main`）をマージ：
   ```powershell
   git merge upstream/master
   ```

### Step A-3: コンフリクトの精密解消
1. 競合している各ファイルをエディタや MCP ツールで精査し、以下の方針で解消します：
   - **設定・ビルド関連 (`package.json`, `manifest.json`, `tsconfig.json` 等)**:
     - upstream で追加・更新された依存パッケージやスクリプトは取り込む。
     - フォーク独自の多言語化依存関係（`i18n` スクリプト等）や設定は維持する。
   - **コードファイル (`.ts`, `.svelte` 等)**:
     - upstream の最新ロジック・修正を取り込む。
     - 既存の `t("...")` 呼び出しを維持する。
     - upstream の更新により**新しく追加された UI 文字列**がある場合は、`t("...")` でラップし、`src/locales/en.json` に登録する。
   - **ワークフロー (`.github/workflows/`)**:
     - フォーク側のワークフロー設計（4象限分類）を最優先し、フォーク用設定を保護する。

### Step A-4: 整合性検証
1. 辞書の整合性をチェック：
   ```powershell
   npm run check-i18n # または node scripts/check-i18n.mjs
   ```
2. 型チェックおよびビルドを検証：
   ```powershell
   npm run check # 定義されている場合
   npm run build
   ```
3. 単体テストを実行（存在する場合）：
   ```powershell
   npm test
   ```

### Step A-5: コミットとPR作成（またはリレーマージ）
1. 解決したファイルをコミット：
   ```powershell
   git commit -m "fix(sync): resolve upstream merge conflicts in i18n-core"
   ```
2. リモートへ push し、`i18n-core` 向けの Pull Request を作成：
   ```powershell
   git push -u origin fix/upstream-sync-<YYYYMMDD>
   gh pr create --base i18n-core --title "fix(sync): resolve upstream merge conflicts" --body "Resolves #<issue-number>"
   ```
3. ユーザーの確認・マージ後、後続ブランチ（`l10n-ja` ➔ `feat-localize` ➔ `master`）へリレーマージ。

---

## 🌐 パターンB: 新規キー翻訳手順（Japanese Translation）

### Step B-1: 未翻訳キーの特定
1. 辞書検証を実行し、不足しているキーを出力：
   ```powershell
   npm run check-i18n
   ```
2. `src/locales/en.json` に存在し、`src/locales/ja.json` に未登録のキーを特定。

### Step B-2: 用語集を参照して翻訳追加
1. **用語集**: [glossary/obsidian-ja.json](https://raw.githubusercontent.com/GennoBou/obsidian-i18n-ops/main/glossary/obsidian-ja.json) を最優先で適用。
2. **スタイルガイド**: [glossary/I18N.md](https://raw.githubusercontent.com/GennoBou/obsidian-i18n-ops/main/glossary/I18N.md) に従い、自然な日本語（「です・ます」調）で記述。
3. **プレースホルダーの厳密一致**: `{name}`, `{count}` などの変数は原文のまま完全に維持。
4. `src/locales/ja.json` に追加。

### Step B-3: 検証とPR作成
1. `npm run check-i18n` でエラー 0 件を確認。
2. `npm run build` を確認。
3. `l10n-ja` へのPRを作成、または指示に応じてリレーマージを実施。
4. 対応した Issue をクローズ。
