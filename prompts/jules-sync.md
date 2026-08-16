# Google Jules 指示書: upstream差分同期 & 差分i18n翻訳

この指示書は、フォーク元（upstream）に新しいコミットや機能追加があった際に、Google Julesが3層ブランチ戦略に沿って差分を取り込み、多言語化・日本語翻訳・リリース準備を行うための手順書です。

---

## 目的
1. `upstream` の最新更新を **多言語化基盤ブランチ (`i18n-core`)** に取り込み、新規UI文字列を `t("...")` でラップして `en.json` を更新。
2. `i18n-core` を **日本語リソースブランチ (`l10n-ja`)** にマージし、共通用語集に従って `ja.json` に対訳を追加。
3. `l10n-ja` を **配布用ブランチ (`main` / `master`)** にマージし、日付バージョン（CalVer `YY.M.D`）を更新して検証・PR作成。

---

## 実行手順

### Step 1: `i18n-core` ブランチの差分同期
1. `i18n-core` ブランチをチェックアウトし、`upstream/master`（または `upstream/main`）を取り込みます:
   ```bash
   git checkout i18n-core
   git merge upstream/master -m "chore(upstream): merge latest upstream changes"
   ```
2. upstreamで新規追加・変更されたUI文字列（設定画面、コマンド、モーダル、通知等）を検出します。
3. `src/i18n.ts` の `t` を使用して `t("English String")` に置換します。
4. 新規キーを `src/locales/en.json` に追加します。
5. コミットしてプッシュ:
   ```bash
   git add .
   git commit -m "feat(i18n): wrap new upstream UI strings with t()"
   git push origin i18n-core
   ```

### Step 2: `l10n-ja` ブランチへの反映 & 日本語翻訳
1. `l10n-ja` ブランチをチェックアウトし、`i18n-core` をマージします:
   ```bash
   git checkout l10n-ja
   git merge i18n-core -m "chore(sync): merge i18n-core into l10n-ja"
   ```
2. 共通用語集（`obsidian-ja.json`, `I18N.md`）を参照し、`src/locales/ja.json` に新規キーの日本語訳を追加します。
3. プレースホルダー（`{name}` など）が英語と完全一致していることを確認します。
4. コミットしてプッシュ:
   ```bash
   git add src/locales/ja.json
   git commit -m "feat(l10n): update Japanese translations for new keys"
   git push origin l10n-ja
   ```

### Step 3: `main` / `master` への反映 & リリース準備
1. `master`（または `main`）ブランチをチェックアウトし、`l10n-ja` をマージします:
   ```bash
   git checkout master
   git merge l10n-ja -m "chore(release): sync l10n-ja into master"
   ```
2. `manifest.json` および `package.json` の `version` を当日日付形式 `YY.M.D`（例: `26.8.17`）に更新します。
   - ※ `manifest.json` の `id: "<plugin-id>-i18n"`, `name: "<Plugin Name> (i18n)"` が維持されていることを確認します。
3. バリデーションとビルドを実行:
   ```bash
   npm run check-i18n
   npm run build
   npm test
   ```
4. 変更をコミットしてプッシュ:
   ```bash
   git add manifest.json package.json
   git commit -m "chore(release): bump version to <YY.M.D>"
   git push origin master
   ```
5. 新しい日付タグ（例: `26.8.17`）をプッシュして GitHub Release を自動発行:
   ```bash
   git tag <YY.M.D>
   git push origin <YY.M.D>
   ```
