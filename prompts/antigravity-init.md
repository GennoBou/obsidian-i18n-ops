# Antigravity 指示書: Obsidianプラグイン初回i18n化 & 日本語リソース初期構築

この指示書は、英語のみに対応している任意のObsidianプラグインをフォークし、多言語化（i18n）および日本語リソースの初期構築を行うための手順書です。

---

## 0. 変数定義（実行時に置換）
- `UPSTREAM_URL`: フォーク元のGitHubリポジトリURL（例: `https://github.com/author/plugin-name`）
- `PLUGIN_NAME`: プラグイン名
- `PLUGIN_ID`: プラグインID（`manifest.json` の `id`）
- `OPS_REPO_PATH`: 本中央管理リポジトリ（`obsidian-i18n-ops`）のローカルパス

---

## 1. ブランチ設計（3層ブランチ戦略）

フォーク先リポジトリでは、将来のupstreamへのPR還元や保守性を担保するため、以下の3層ブランチ構成で運用します。

```
upstream/master (オリジナル)
       │
       ▼
[ 1. i18n-core ] ─── (将来 upstream へのPR可能)
   ・コードの t() 化
   ・src/i18n.ts (軽量アダプター)
   ・src/locales/en.json (ベース辞書)
       │
       ▼
[ 2. l10n-ja ] (日本語化)
   ・src/locales/ja.json (日本語辞書)
       │
       ▼
[ 3. main / master ] (BRAT配布用)
   ・manifest.json の id / name 改名 ("<id>-i18n", "<Name> (i18n)")
   ・README.md (BRATインストール案内)
   ・.github/workflows/ (定期追従 & BRATリリースCI)
   ・CalVer 日付バージョン (YY.M.D / 同日2回目以降は YY.M.D.N)
```

---

## Step 1: フォークリポジトリの作成とクローン

1. GitHub CLI を使用してフォークを作成し、ローカルにクローンします。
   ```bash
   gh repo fork <UPSTREAM_URL> --fork-name <PLUGIN_ID>-i18n --clone
   cd <PLUGIN_ID>-i18n
   ```
2. upstream リモートが設定されていることを確認します。
   ```bash
   git remote -v
   ```

---

## Step 2: 多言語化基盤ブランチ (`i18n-core`) の構築

言語中立なi18n化を行い、将来upstreamへそのままPRを出せる状態を作ります。

1. upstreamの最新から `i18n-core` ブランチを作成:
   ```bash
   git checkout -b i18n-core upstream/master # (または upstream/main)
   ```
2. `templates/i18n.ts` を `src/i18n.ts` にコピー。
3. `scripts/check-i18n.mjs` を `scripts/check-i18n.mjs` にコピー。
4. `package.json` の `scripts` に以下を追加:
   ```json
   "check-i18n": "node scripts/check-i18n.mjs"
   ```
5. プラグインの全ソースコードをスキャンし、ハードコードされたUI文字列を `t("English String")` に置換。
   - **対象**: 設定画面 (`setName`, `setDesc`等)、コマンド名、モーダル、Notice通知、ツールチップ
   - **除外**: 内部ID、設定キー名、CSSクラス、URL、正規表現、ログメッセージ
6. 原文キーをまとめた `src/locales/en.json` を生成。
7. コミットしてリモートにプッシュ:
   ```bash
   git add .
   git commit -m "feat(i18n): add lightweight i18n layer and wrap UI strings with t()"
   git push -u origin i18n-core
   ```

---

## Step 3: 日本語リソースブランチ (`l10n-ja`) の構築

1. `i18n-core` から `l10n-ja` ブランチを作成:
   ```bash
   git checkout -b l10n-ja i18n-core
   ```
2. `obsidian-i18n-ops/glossary/obsidian-ja.json` および `glossary/I18N.md` のルールに従い、`src/locales/ja.json` を生成。
3. プレースホルダー（`{name}`, `{count}` 等）が英語・日本語で完全一致していることを確認。
4. コミットしてリモートにプッシュ:
   ```bash
   git add src/locales/ja.json
   git commit -m "feat(l10n): add Japanese translation dictionary"
   git push -u origin l10n-ja
   ```

---

## Step 4: BRAT配布用ブランチ (`main` / `master`) の構築

Obsidianでオリジナルプラグインと衝突せず共存・利用できるように設定します。

1. `l10n-ja` から `main`（または `master`）へ切り替え/マージ:
   ```bash
   git checkout master # (または git checkout -b main l10n-ja)
   git merge l10n-ja
   ```
2. **`manifest.json` の改名（衝突防止）**:
   - `id`: `"<original-id>-i18n"` に変更（例: `"quickadd-i18n"`）
   - `name`: `"<Original Name> (i18n)"` に変更（例: `"QuickAdd (i18n)"`）
   - `version`: 当日の日付バージョン `YY.M.D`（例: `"26.8.26"`。同日2回目以降は `YY.M.D.N` 形式 例: `"26.8.26.1"`）
3. **`package.json` の `version` 更新**:
   - `version` を当日日付形式 `YY.M.D`（例: `"26.8.26"` / 同日2回目以降は `"26.8.26.1"`）に更新。
4. **`README.md` 冒頭にBRAT利用案内を追加**:
   ```markdown
   > [!NOTE]
   > **日本語版 (i18n Fork) について**
   > 本リポジトリは、[オリジナルプラグイン](<UPSTREAM_URL>) を多言語化 (i18n) し、日本語リソースを追加したフォーク版です。
   > 個人利用・コミュニティ提供を目的としており、Obsidianへのインストールは **[Obsidian42 - BRAT](https://github.com/TfTHacker/obsidian42-brat)** プラグイン経由で行ってください。
   >
   > **BRATでのインストール手順**:
   > 1. Obsidianで BRAT プラグインを有効化
   > 2. コマンドパレットから `BRAT: Plugins: Add a beta plugin for testing` を実行
   > 3. 本リポジトリのURL (`https://github.com/<YOUR_ACCOUNT>/<FORK_REPO>`) を入力
   
   ---
   ```
5. **CIワークフローの配置 & upstream ワークフローの汎用4象限分類・無効化**:
   - `templates/upstream-sync.yml` を `.github/workflows/upstream-sync.yml` に配置。
   - `templates/i18n-ci.yml` を `.github/workflows/i18n-ci.yml` に配置。
   - `templates/brat-release.yml` を `.github/workflows/brat-release.yml` に配置。
   - **ワークフローの4象限分類＆無効化の判定ルール**:
     詳細は `docs/ci-workflow-guidelines.md` を参照し、フォーク元の既存 `.github/workflows/*.yml` を検査して以下のように判定・対応する。
     1. **Category 1: 本家固有・外部認証依存フロー（無効化）**:
        - Secrets（GitHub App / Bot トークン等）参照、公式コミュニティPR、Docsデプロイ、Stale bot 等
        - 対応: コードを削除せず `gh workflow disable <名前>` で無効化（upstream更新時のコンフリクトを原理的に防止）。
     2. **Category 2: 過剰・重複テストフロー（無効化）**:
        - OSマトリクス（macOS / Windows）、CodeQL、重複するフルテスト
        - 対応: CI待ち時間と無料枠消費を削減するため `gh workflow disable <名前>` で無効化。
     3. **Category 3: 多言語化高速CI（新設・運用）**:
        - `.github/workflows/i18n-ci.yml` で Ubuntu 単一環境にて `check-i18n` + `build` + 単体テストを1〜2分で実行。
     4. **Category 4: BRAT配布リリース（新設・運用）**:
        - `.github/workflows/brat-release.yml` で CalVer 日付タグ（`YY.M.D` / 同日2回目以降は `YY.M.D.N`）によるアセット付きRelease発行を自動化。

---

## Step 5: バリデーション・ビルド・初回リリース発行

1. **i18n整合性チェック**:
   ```bash
   npm run check-i18n
   ```
2. **ビルド & 既存Lint/型チェック/テスト実行**:
   - `npm run check-i18n` のほか、プラグイン既存の検証コマンドを実行し、新規追加スクリプトや差分がルール違反していないことを確認:
   ```bash
   npm run build
   npm test
   # プラグインに定義されている場合
   npm run lint || pnpm lint
   npm run check # (Svelte check等)
   ```
3. **コミット & プッシュ**:
   ```bash
   git add .
   git commit -m "feat(release): configure plugin id/name for i18n and setup BRAT release"
   git push -u origin master
   ```
4. **不要な upstream ワークフローの一括無効化 (GitHub CLI)**:
   - Category 1 および Category 2 に該当する既存ワークフローを無効化:
   ```bash
   # 例: ワークフロー一覧を確認して無効化
   gh workflow list
   gh workflow disable "<本家リリース/テストワークフロー名>"
   ```
5. **GitタグのプッシュによるBRATリリース発行**:
   - **初回リリース**: `git tag <YY.M.D>`（例: `git tag 26.8.26`）
   - **同日2回目以降のリビジョン**: `git tag <YY.M.D.N>`（例: `git tag 26.8.26.1`）
   - ※ `26.8.26-1` のようなハイフン式はSemVer仕様上プレリリース（＝正式版より古い）と判定されBRAT更新が検知されなくなるため、**必ずピリオド式 `.N` を使用** してください。
   ```bash
   git tag 26.8.26 # (同日2回目以降なら 26.8.26.1)
   git push origin 26.8.26
   ```
   GitHub Actions（`brat-release.yml`）が自動起動し、`main.js`, `manifest.json`, `styles.css` を含む GitHub Release を発行します。
