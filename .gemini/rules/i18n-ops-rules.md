# Obsidian 多言語化運用（i18n-ops）Antigravity 行動ルール

本ワークスペースにおいて、ユーザーからプラグインの同期Issue解決やコンフリクト解消を依頼された場合、以下のプロトコルを厳守して自律的に解決にあたること。

---

## 1. Issue 確認プロトコル
- ユーザーから「○○（プラグイン名）のissueを確認/解決して」と指示された場合、まず `gh issue list --repo GennoBou/<plugin-repo>` またはローカルの `workspace/<plugin-name>` から `gh issue list` を実行する。
- 最新の同期Issue（`⚠️ [i18n-sync]` または `🌐 [i18n-sync]`、旧 `[Jules Sync]`）を `gh issue view <issue-number>` で詳細確認する。
- Issue本文に記載された Upstream Commit と競合ファイル、または未翻訳キーのリストを読み取る。

## 2. 解決実行プロトコル（prompts/antigravity-sync.md に準拠）

### パターンA: Upstream Conflict（競合解消）の場合
1. `workspace/<plugin-name>` にて `git fetch origin` および `git fetch upstream` を行う。
2. 必ず `i18n-core` ブランチを起点に作業ブランチ（`fix/upstream-sync-YYYYMMDD`）を作成する。
3. `git merge upstream/master`（または `upstream/main`）を実行する。
4. 競合ファイルを解消する：
   - 既存のフォーク固有ファイル（`.github/workflows/`, `manifest.json`, `package.json`）を破壊・初期化しない。
   - 新規追加された UI 文字列があれば `t("...")` でラップし、`src/locales/en.json` に追加する。
5. 検証を実行する：
   - `npm run check-i18n`（または `node scripts/check-i18n.mjs`）
   - `npm run check`（定義されている場合）
   - `npm run build`
6. `i18n-core` への Pull Request を作成（またはユーザーの指示に応じて直接リレーマージ）。
7. Issue をクローズ（または PR に `Resolves #<issue>` を含める）。

### パターンB: New Untranslated Keys（新規キー翻訳）の場合
1. `workspace/<plugin-name>` にて `npm run check-i18n` を実行し、不足キーを特定する。
2. `glossary/obsidian-ja.json` および `glossary/I18N.md` に準拠して `src/locales/ja.json` に日本語訳を追加する。
   - プレースホルダー（`{name}`, `{count}` 等）は完全一致させる。
   - 自然な日本語（「です・ます」調）で記述する。
3. `npm run check-i18n` でエラー 0 件を確認後、PR作成またはリレーマージを行う。
