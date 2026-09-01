# Antigravity 指示書: Obsidianプラグイン初回i18n化 & 日本語リソース初期構築

この指示書は、英語のみに対応している任意のObsidianプラグインをフォークし、多言語化（i18n）および日本語リソースの初期構築を行うための手順書です。

---

## 0. 変数定義（実行時に置換）

- `UPSTREAM_URL`: フォーク元のGitHubリポジトリURL（例: `https://github.com/author/plugin-name`）
- `PLUGIN_NAME`: プラグイン名
- `PLUGIN_ID`: プラグインID（`manifest.json` の `id`）
- `OPS_REPO_PATH`: 本中央管理リポジトリ（`obsidian-i18n-ops`）のローカルパス

---

## 1. ブランチ設計（4層ブランチ戦略）

フォーク先リポジトリでは、将来のupstreamへのPR還元や保守性を担保しつつ、ビルド不要の動的言語追加を可能にするため、以下の**4層ブランチ構成**で運用します。

```
upstream/master (オリジナル)
       │
       ▼
[ 1. i18n-core ] ─── (将来 upstream へのPR可能)
   ・コードの t() 化
   ・src/i18n.ts (最小アダプター)
   ・src/locales/en.json (ベース辞書)
       │
       ▼
[ 2. l10n-ja ] (日本語化)
   ・src/locales/ja.json (日本語辞書)
       │
       ▼
[ 3. feat-localize ] (動的ローカライズ機能)
   ・src/i18n.ts に initLocalizeJson() を接続
   ・main.ts の onload() 先頭で await initLocalizeJson(this.app, this.manifest)
   ・localize.json (雛形テンプレート)
       │
       ▼
[ 4. main / master ] (BRAT配布用)
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

3. **Serena MCP のアクティベート**:
   - 作業対象プロジェクトを Serena MCP に登録・アクティベートします。
   - `serena:activate_project`（引数 `project: "<クローンした絶対パス>"`）を呼び出します。
   - TypeScript 言語サーバー（LSP）とセマンティック探索機能を有効化し、巨大ファイルでの安全なリファクタリング・リアルタイム構文検証（`get_diagnostics_for_file`）環境を整えます。

---

## Step 1.5: 事前適合性チェック（Pre-flight Checks）

破壊的な変更や不適切なファイル配置を防ぐため、コード改変を開始する前に以下の3つの前提条件を自動検証します。**いずれかのチェックに抵触した場合は、処理を即座に中断（Abort）してください。**

### ① Obsidian プラグイン適合性チェック（Fail-Fast）
リポジトリ直下に有効な `manifest.json` が存在し、Obsidianプラグインの必須フィールドが含まれているかを検証します。

```bash
node -e "
const fs = require('fs');
if (!fs.existsSync('manifest.json')) {
  console.error('❌ [CRITICAL ERROR] manifest.json がルートに存在しません。Obsidianプラグインではないため処理を中断します。');
  process.exit(1);
}
try {
  const manifest = JSON.parse(fs.readFileSync('manifest.json', 'utf8'));
  if (!manifest.id || !manifest.name || !manifest.minAppVersion) {
    console.error('❌ [CRITICAL ERROR] manifest.json に必須プロパティ(id, name, minAppVersion)が不足しています。Obsidianプラグインではないため処理を中断します。');
    process.exit(1);
  }
  console.log('✅ Obsidianプラグインのメタデータを確認しました: ' + manifest.name + ' (' + manifest.id + ')');
} catch (e) {
  console.error('❌ [CRITICAL ERROR] manifest.json のJSONパースに失敗しました。処理を中断します。');
  process.exit(1);
}
"
```
> [!CAUTION]
> このチェックでエラーが出た場合は、**ブランチ作成やファイルコピーを一切行わず、ユーザーに「Obsidianプラグインではないため処理を中止しました」と報告して終了**してください。

---

### ② 既存多言語化（i18n）対応状況チェック
すでに多言語化が組み込まれていないかを検証します。

- 以下のファイルやディレクトリが存在するか確認:
  - `src/i18n.ts`, `src/i18n/`, `locales/`, `src/locales/`, `lang/`
  - ソースコード内に `i18next`, `t(`, `obsidian-i18n` 等の呼び出しが存在するか
- **判定**:
  - すでに i18n 機構が存在する場合：**本手順（4層ブランチや全コードの `t()` 化）を停止**し、「すでに多言語化対応されています。辞書追加（`l10n-ja`）のみを行うか確認してください」とユーザーに通知して待機します。

---

### ③ ベースラインビルド検証（Clean Slate Check）
upstream（本家）のコードが正常にビルドできるクリーンな状態かを確認します。

```bash
npm install # または pnpm install / yarn
npm run build
```
- **判定**: upstream 自体がビルドエラーになる場合、多言語化作業に起因しない問題であるため、ユーザーにエラーを報告して対応方針を確認します。

---

## Step 2: 多言語化基盤ブランチ (`i18n-core`) の構築

言語中立なi18n化を行い、将来upstreamへそのままPRを出せる状態を作ります（この段階では外部ファイル読み込み等のフォーク独自ロジックは含めず、純粋な `t()` 化とベース辞書に留めます）。

1. upstreamの最新から `i18n-core` ブランチを作成:

   ```bash
   git checkout -b i18n-core upstream/master # (または upstream/main)
   ```

2. `templates/i18n.ts` を `src/i18n.ts` にコピー（※ この段階では `en.json` のみを読み込むシンプルな構成）。
3. `scripts/check-i18n.mjs` を `scripts/check-i18n.mjs` にコピー。
4. `package.json` の `scripts` に以下を追加:

   ```json
   "check-i18n": "node scripts/check-i18n.mjs"
   ```

5. プラグインの全ソースコードをスキャンし、ハードコードされたUI文字列を `t(...)` に置換。
   - **対象**: 設定画面 (`setName`, `setDesc`, `addOptions` の選択肢等)、コマンド名、モーダル、Notice通知、ツールチップ、aria-label
   - **除外**: 内部ID、設定キー名、CSSクラス、URL、正規表現、ログメッセージ
   - **長文文字列のキー化規則（スラッグ#ハッシュID方式）**:
     - 半角60文字超の長文説明文や改行を含む文章、クォート等のエスケープが複雑な文章は、改行・エスケープ不一致事故を防ぐため `[先頭24文字スラッグ]...#[SHA256先頭6桁]` の固定ID（例: `t("Available placeholders...#5e47b9")`）を生成してキー化する。
     - 短いUI（ボタン名、コマンド名、設定名）はそのまま原文キーを使用する。
     - **キー生成ロジック（標準関数 `toKey`）**:
       ```javascript
       import crypto from "crypto";

       function toKey(originalText) {
           const normalized = originalText.replace(/\s+/g, " ").trim();
           // 60文字以下で改行やエスケープのない短い文はそのまま原文キー
           if (normalized.length <= 60 && !originalText.includes("\n") && !originalText.includes('"') && !originalText.includes("'")) {
               return normalized;
           }
           // 長文・改行を含む文はスラッグ（英数字・ハイフンのみ24文字）＋SHA-256先頭6桁
           const hash = crypto.createHash("sha256").update(normalized).digest("hex").slice(0, 6);
           const slug = normalized.replace(/[^a-zA-Z0-9\s-]/g, " ").replace(/\s+/g, " ").trim().slice(0, 24).trim();
           return `${slug}...#${hash}`;
       }
       ```
6. **未ラップUI文字列の静的スキャン（漏れゼロ検証）**:
   - `src/` 配下の全ファイルに対し、`.setName()`, `.setDesc()`, `addOptions()`, `new Notice()`, `aria-label` 等に生の文字列リテラル（`t()` で囲まれていない文字列）が残っていないか、静的スキャン（正規表現やAST）を実行し、未ラップ箇所が 0 件であることを検証する。
   - ※ 改行を含む複数行の `setDesc`、テンプレートリテラル（`` `...` ``）、ドロップダウンの選択肢オブジェクト（例: `{ hide: "Hide" }`）、文字列連結（`+`）、動的変数（三項演算子等）も漏れなく `t()` 化されていることを確認する。
7. 原文キーをまとめた `src/locales/en.json` を生成。
   - **重要**: スラッグ#ハッシュIDのキーに対する値（Value）には、プレースホルダーを含む**元の完全な英語全文**を格納すること（辞書チェッカーがプレースホルダー整合性を検証できるようにするため）。
8. `npm run check-i18n` および `npm run build`（型チェック・ビルド）を実行して検証。
9. コミットしてリモートにプッシュ:

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
4. `npm run check-i18n` を実行し、全キーの存在とプレースホルダーの一致（Warnings: 0）を検証。
5. コミットしてリモートにプッシュ:

   ```bash
   git add src/locales/ja.json
   git commit -m "feat(l10n): add Japanese translation dictionary"
   git push -u origin l10n-ja
   ```

---

## Step 4: 動的ローカライズ層ブランチ (`feat-localize`) の構築

ビルド不要でユーザーや他言語翻訳者が `localize.json` を編集して即座に自国語化・オーバーライドできる拡張機能を追加します。

1. `l10n-ja` から `feat-localize` ブランチを作成:

   ```bash
   git checkout -b feat-localize l10n-ja
   ```

2. `src/locales/en.json` の内容を `translations` に含めた `localize.json` テンプレートをルートに生成:

   ```bash
   node -e "const fs = require('fs'); const en = JSON.parse(fs.readFileSync('src/locales/en.json', 'utf8')); fs.writeFileSync('localize.json', JSON.stringify({ '\$schema': 'https://json-schema.org/draft/2020-12/schema', description: 'Custom UI translation overlay. Set language code (e.g. \"de\", \"fr\") and modify translations.', language: '', translations: en }, null, 2) + '\n');"
   ```

   生成される `localize.json` の構造:
   ```json
   {
     "$schema": "https://json-schema.org/draft/2020-12/schema",
     "description": "Custom UI translation overlay. Set language code (e.g. \"de\", \"fr\") and modify translations.",
     "language": "",
     "translations": {
       "Settings": "Settings",
       "Enable feature": "Enable feature",
       ... (en.json の全内容)
     }
   }
   ```
   > [!IMPORTANT]
   > `localize.json` はユーザーが Vault 内で編集したカスタム設定を保持するため、**GitHub Release（BRAT配布アセット）には含めません**。ユーザーの Vault 内でプラグインが初回起動した際に `initLocalizeJson` がローカルで自動生成します（BRAT更新による強制上書き・カスタマイズ消去を防止するため）。

3. `src/i18n.ts` に `initLocalizeJson` が含まれていることを確認し、プラグインのエントリーポイント（`main.ts` 等）の `onload()` 先頭で呼び出す:

   ```typescript
   import { initLocalizeJson } from "./i18n";

   export default class MyPlugin extends Plugin {
       async onload() {
           // UI構築前に外部 localize.json を動的ロード
           await initLocalizeJson(this.app, this.manifest);

           // 既存の onload 処理...
       }
   }
   ```

4. コミットしてリモートにプッシュ:

   ```bash
   git add .
   git commit -m "feat(i18n): enable dynamic localization via localize.json"
   git push -u origin feat-localize
   ```

---

## Step 5: BRAT配布用ブランチ (`main` / `master`) の構築

Obsidianでオリジナルプラグインと衝突せず共存・利用できるように設定します。

1. `feat-localize` から `main`（または `master`）へ切り替え/マージ:

   ```bash
   git checkout master # (または git checkout -b main feat-localize)
   git merge feat-localize
   ```

2. **`manifest.json` の改名（衝突防止）**:
   - `id`: `"<original-id>-i18n"` に変更（例: `"quickadd-i18n"`）
   - `name`: `"<Original Name> (i18n)"` に変更（例: `"QuickAdd (i18n)"`）
   - `version`: 当日の日付バージョン `YY.M.D`（例: `"26.8.26"`。同日2回目以降は `YY.M.D.N` 形式 例: `"26.8.26.1"`）
3. **`package.json` の `version` 更新**:
   - `version` を当日日付形式 `YY.M.D`（例: `"26.8.26"` / 同日2回目以降は `"26.8.26.1"`）に更新。
4. **`README.md` 冒頭に案内を追加**:

   ```markdown
   > [!NOTE]
   > **About this i18n Fork / 多言語版について**
   >
   > This repository is a fork of the [original plugin](<UPSTREAM_URL>) that introduces internationalization (i18n) support and Japanese localization resources.
   > It is intended for personal and community use. To install this plugin in Obsidian, please use the **[Obsidian42 - BRAT](https://github.com/TfTHacker/obsidian42-brat)** plugin.
   > Once the upstream plugin officially supports internationalization and Japanese locales, this repository will be archived.
   >
   > **Installation via BRAT**:
   > 1. Enable the BRAT plugin in Obsidian.
   > 2. Run `BRAT: Plugins: Add a beta plugin for testing` from the Command Palette.
   > 3. Enter this repository URL: `https://github.com/<YOUR_ACCOUNT>/<FORK_REPO>`
   >
   > **Custom Translations (localize.json)**:
   > - You can add custom translations or override text by editing `localize.json` in the plugin folder (`.obsidian/plugins/<PLUGIN_ID>-i18n/`).
   > - Set your target language code in `"language"` (e.g. `"en"`, `"ja"`, `"de"`), modify `"resource"`, and reload Obsidian.
   > - Deleting `localize.json` and reloading Obsidian will reset it to the default template.
   >
   > ---
   >
   > 本リポジトリは、[オリジナルプラグイン](<UPSTREAM_URL>) を多言語化 (i18n) し、日本語リソースを追加したフォーク版です。
   > 個人利用・コミュニティ提供を目的としており、Obsidianへのインストールは **[Obsidian42 - BRAT](https://github.com/TfTHacker/obsidian42-brat)** プラグイン経由で行ってください。
   > 本家が多言語対応と日本語ロケールを公式実装したとき、本リポジトリの役目は終えアーカイブされます。
   >
   > **BRATでのインストール手順**:
   > 1. Obsidianで BRAT プラグインを有効化
   > 2. コマンドパレットから `BRAT: Plugins: Add a beta plugin for testing` を実行
   > 3. 本リポジトリのURL (`https://github.com/<YOUR_ACCOUNT>/<FORK_REPO>`) を入力
   >
   > **独自翻訳の追加・カスタマイズ (localize.json)**:
   > - プラグインフォルダ内の `localize.json` を編集することで、独自翻訳の追加や上書きが可能です。
   > - `"language"` に使用したい言語コード（例: 英語=`"en"`, 日本語=`"ja"`, ドイツ語=`"de"` 等）を入力し、`"resource"` 以下を書き換えてアプリを再起動すると反映されます。
   > - `localize.json` を削除してアプリを再起動すると、初期状態に自動復元されます。
   
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
        - `.github/workflows/i18n-ci.yml` で Ubuntu 単一環境にて `check-i18n` + `check` / `lint` + `build` を **30秒〜45秒** で実行（過剰な単体テストは除外）。
     4. **Category 4: BRAT配布リリース（新設・運用）**:
        - `.github/workflows/brat-release.yml` で CalVer 日付タグ（`YY.M.D` / 同日2回目以降は `YY.M.D.N`）によるアセット付きRelease発行を自動化。

---

## Step 6: バリデーション・ビルド・初回リリース発行

1. **i18n整合性チェック**:

   ```bash
   npm run check-i18n
   ```

2. **ビルド & 既存Lint/型チェック/ローカルテスト実行**:
   - `npm run check-i18n` のほか、プラグイン既存の検証コマンドを実行し、新規追加スクリプトや差分がルール違反していないことを確認:

   ```bash
   npm run build
   npm test # ローカルでの品質確認
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

5. **リポジトリ保護・CI権限の自動構成 (GitHub CLI)**:
   - GitHub Actions の書き込み権限有効化（`upstream-sync` や `brat-release` 実行用）と、`master` ブランチ保護ルールセット（誤削除・Force push 防止、Actions/管理者バイパス許可）を一括適用します:

   ```powershell
   # PowerShell の場合:
   pwsh <OPS_REPO_PATH>/scripts/setup-repo-security.ps1
   ```
   ```bash
   # Bash の場合:
   <OPS_REPO_PATH>/scripts/setup-repo-security.sh
   ```

6. **GitタグのプッシュによるBRATリリース発行**:
   - **初回リリース**: `git tag <YY.M.D>`（例: `git tag 26.8.26`）
   - **同日2回目以降のリビジョン**: `git tag <YY.M.D.N>`（例: `git tag 26.8.26.1`）
   - ※ `26.8.26-1` のようなハイフン式はSemVer仕様上プレリリース（＝正式版より古い）と判定されBRAT更新が検知されなくなるため、**必ずピリオド式 `.N` を使用** してください。

   ```bash
   git tag 26.8.26 # (同日2回目以降なら 26.8.26.1)
   git push origin 26.8.26
   ```

   GitHub Actions（`brat-release.yml`）が自動起動し、`main.js`, `manifest.json`, `styles.css` を含む GitHub Release を発行します。

7. **CI実行時間の実測確認（過剰動作防止）**:
   - GitHub Actions の実行時間を実測し、目標基準（1分以内）を達成しているか確認します:

   ```bash
   gh run list -L 5
   # i18n CI: 30〜45秒
   # Release for BRAT: 40〜50秒
   ```
