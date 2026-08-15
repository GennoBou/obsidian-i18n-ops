# Google Jules 指示書: upstream差分同期 & 差分i18n翻訳

この指示書は、フォーク元（upstream）に新しいコミットや機能追加があった際に、Google Julesが差分を取り込み、新規UI文字列のi18n化と日本語翻訳を行うための手順書です。

---

## 目的
1. フォーク元リポジトリの最新更新を同期用ブランチ（`upstream-sync/YYYY-MM-DD`）に取り込む。
2. upstreamで新規追加・変更されたUI文字列を検知し、`t("...")` でラップする。
3. `src/locales/en.json` および `src/locales/ja.json` に対訳を追加・更新する。
4. ビルド・テスト・i18n検証をパスした状態でPRを作成する。

---

## 実行手順

### Step 1: upstream差分の確認
1. `upstream/main`（または `upstream/master`）からの差分コミットおよび変更ファイル一覧を確認します。
2. 変更されたファイルの中から、UIに関わるファイル（設定画面、モーダル、コマンド、通知等）を特定します。

### Step 2: 新規UI文字列の `t()` 化
1. upstreamで追加された英語文字列で、`t("...")` にラップされていないものを検出します。
2. 既存の `src/i18n.ts` から `t` をインポートし、該当箇所を `t("English String")` に置換します。
3. 既存のコード規約・スタイルを破壊しないように注意してください。

### Step 3: 辞書ファイル (`locales/en.json`, `locales/ja.json`) の更新
1. 新規に追加した原文キーを `src/locales/en.json` に追加します。
2. 共通用語集ルール（`obsidian-ja.json`, `I18N.md`）を参照し、`src/locales/ja.json` に自然で正確な日本語訳を追加します。
3. プレースホルダー（`{name}` など）が存在する場合、日本語側でも同じ名前のプレースホルダーを維持してください。

### Step 4: バリデーションとビルド確認
1. i18n検証スクリプトを実行:
   ```bash
   npm run check-i18n
   ```
2. ビルドとテストを実行:
   ```bash
   npm run build
   npm test
   ```
3. エラーがある場合は修正します。

### Step 5: コミットとPR作成
1. 変更内容を分かりやすいコミットメッセージでコミットします。
   - 例: `feat(i18n): sync upstream changes and update ja translations`
2. `main` ブランチへのプルリクエストを作成します。
