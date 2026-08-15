# Antigravity 指示書: Obsidianプラグイン初回i18n化 & 日本語リソース初期構築

この指示書は、英語のみに対応している任意のObsidianプラグインをフォークし、多言語化（i18n）および日本語リソースの初期構築を行うための手順書です。

---

## 0. 変数定義（実行時に置換）
- `UPSTREAM_URL`: フォーク元のGitHubリポジトリURL（例: `https://github.com/author/plugin-name`）
- `PLUGIN_NAME`: プラグイン名
- `OPS_REPO_PATH`: 本中央管理リポジトリ（`obsidian-i18n-ops`）のローカルパス

---

## Step 1: フォークリポジトリの作成とクローン

1. GitHub CLI を使用してフォークを作成し、ローカルにクローンします。
   ```bash
   gh repo fork <UPSTREAM_URL> --clone
   cd <PLUGIN_NAME>
   ```
2. upstream リモートが設定されていることを確認します。
   ```bash
   git remote -v
   ```

---

## Step 2: README.md 冒頭へのi18n・BRAT利用案内追加

フォーク先リポジトリの `README.md` の最上部に、以下の告知ブロックを追加します。

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

---

## Step 3: i18n基盤コードの配置

1. `templates/i18n.ts` をプラグインのソースコードディレクトリ（通常 `src/i18n.ts`）にコピーします。
2. `src/locales/` ディレクトリを作成します。
3. `scripts/check-i18n.ts` をプラグインの `scripts/check-i18n.ts` にコピーします。
4. `package.json` の `scripts` に以下を追加します:
   ```json
   "check-i18n": "ts-node scripts/check-i18n.ts"
   ```

---

## Step 4: UI文字列の探索と `t()` 置換

プラグインの全ソースコード（`.ts`, `.tsx`, `.svelte`, `.js` 等）をスキャンし、ハードコードされたユーザー向けUI文字列を `t("English String")` に置換します。

### 対象とする文字列
- **設定画面 (Settings Tab)**: `setName("...")`, `setDesc("...")`, `setPlaceholder("...")`, `setButtonText("...")`
- **コマンド (Commands)**: `addCommand({ id: '...', name: t("...") })`
- **モーダル / ダイアログ (Modals)**: タイトル、ボタン名、説明テキスト
- **通知 (Notices)**: `new Notice(t("..."))`
- **リボンアイコン / ステータスバー**: ツールチップ文言 `aria-label`, `title`

### 対象外とする文字列（`t()` でラップしてはいけないもの）
- 内部ID（コマンドID、設定キー名、CSSクラス名、HTMLタグ名）
- ファイル拡張子、URL、正規表現、Markdown構文記号
- ログメッセージ（`console.log`, `console.error` 等の開発者用ログ）
- イベント名

---

## Step 5: 翻訳辞書 (`locales/en.json`, `locales/ja.json`) の生成

1. 抽出したすべての原文キーから `src/locales/en.json` を生成（`"Key": "Key"` の形式）。
2. `obsidian-i18n-ops/glossary/obsidian-ja.json` および `glossary/I18N.md` のルールに従い、`src/locales/ja.json` を生成。
3. プレースホルダー（`{name}`, `{count}` 等）は英語・日本語で完全一致させること。

---

## Step 6: バリデーション & ビルド検証

1. 依存パッケージをインストール:
   ```bash
   npm install
   ```
2. i18n整合性チェックを実行:
   ```bash
   npm run check-i18n
   ```
3. TypeScriptビルドおよびテストを実行:
   ```bash
   npm run build
   npm test
   ```

---

## Step 7: 定期追従CIワークフローの配置

1. `templates/upstream-sync.yml` を `.github/workflows/upstream-sync.yml` にコピー。
2. 変更をコミットし、フォーク先リポジトリの `main`（または `master`）にプッシュ。
