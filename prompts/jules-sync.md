# Google Jules 指示書: upstream差分同期 & 差分i18n翻訳

この指示書は、フォーク元（upstream）に新しいコミットや機能追加があった際、または GitHub Issue（`[Jules Sync]`）が作成された際に、Google Jules（AIエージェント）が3層ブランチ戦略に沿って差分同期・多言語化・日本語翻訳・リリースを完結させるための手順書です。

---

## 🎯 目的
1. upstream の最新更新を **多言語化基盤層 (`i18n-core`)** に取り込み、新規UI文字列を `t("...")` でラップして `src/locales/en.json` を更新（またはコンフリクトを解消）。
2. `i18n-core` を **日本語リソース層 (`l10n-ja`)** にマージし、公式用語集に従って `src/locales/ja.json` に対訳を追加。
3. `l10n-ja` を **配布用層 (`master` / `main`)** にマージし、CalVer日付バージョン（`YY.M.D[.N]`）を更新して検証・リリース発行。

---

## 📚 参照リソース（用語集・スタイルガイド）
翻訳時は必ず以下の中央用語集・ルールを参照してください：
- **Obsidian 公式UI標準用語集**: [glossary/obsidian-ja.json](https://raw.githubusercontent.com/GennoBou/obsidian-i18n-ops/main/glossary/obsidian-ja.json)
- **スタイルガイド & 翻訳ルール**: [glossary/I18N.md](https://raw.githubusercontent.com/GennoBou/obsidian-i18n-ops/main/glossary/I18N.md)

---

## 🛠️ 実行手順（2つのシナリオ）

### シナリオ A: 新規UI文字列の追加検知時（未翻訳キーの解消）

#### Step 1: `i18n-core` の確認とプッシュ
1. `i18n-core` ブランチをチェックアウト:
   ```bash
   git checkout i18n-core
   git pull origin i18n-core
   ```
2. upstream の新規UI文字列がすべて `t("English")` でラップされ、`src/locales/en.json` にキーが存在することを確認。
3. 漏れがあれば置換・追加してプッシュ:
   ```bash
   git add .
   git commit -m "feat(i18n): wrap new UI strings with t()"
   git push origin i18n-core
   ```

#### Step 2: `l10n-ja` ブランチでの日本語翻訳
1. `l10n-ja` ブランチをチェックアウトし、`i18n-core` をマージ:
   ```bash
   git checkout l10n-ja
   git merge i18n-core -m "chore(sync): merge i18n-core into l10n-ja"
   ```
2. `glossary/obsidian-ja.json` を参照し、`src/locales/ja.json` に不足しているキーの日本語訳を追加。
   - **文体**: 簡潔で自然な日本語（「です・ます」調推奨）。
   - **プレースホルダー**: `{name}`, `{count}` などの変数は原文と完全一致させる。
3. 辞書検証スクリプトを実行し、エラーが0件であることを確認:
   ```bash
   npm run check-i18n
   ```
4. コミットしてプッシュ:
   ```bash
   git add src/locales/ja.json
   git commit -m "feat(l10n): add Japanese translations for upstream changes"
   git push origin l10n-ja
   ```

#### Step 3: `master` への反映 & CalVer リリース
1. `master`（または `main`）ブランチをチェックアウトし、`l10n-ja` をマージ:
   ```bash
   git checkout master
   git merge l10n-ja -m "chore(release): sync l10n-ja into master"
   ```
2. **当日の CalVer 日付バージョンを決定**:
   - 当日初回: `YY.M.D`（例: `26.8.26`）
   - 同日2回目以降: `YY.M.D.N`（例: `26.8.26.1`, `26.8.26.2`）※ハイフン禁止。
3. `manifest.json` および `package.json` の `version` を更新。
   - ※ `manifest.json` の `id: "<id>-i18n"`, `name: "<Name> (i18n)"` が維持されていることを確認。
4. 検証とビルドを実行:
   ```bash
   npm run check
   npm run build
   ```
5. コミット、プッシュ、および日付タグをプッシュ:
   ```bash
   git add manifest.json package.json
   git commit -m "chore(release): bump version to <YY.M.D[.N]>"
   git push origin master
   git tag <YY.M.D[.N]>
   git push origin <YY.M.D[.N]>
   ```
   `brat-release.yml` が自動起動し、BRAT用 GitHub Release が発行されます。

---

### シナリオ B: マージコンフリクト発生時

1. `i18n-core` ブランチで upstream の最新を取り込み:
   ```bash
   git checkout i18n-core
   git fetch upstream
   git merge upstream/master # (または upstream/main)
   ```
2. 競合ファイルを解消:
   - upstream側の新コードを採用しつつ、UI文字列が追加・変更されている場合は `t("...")` でラップ。
   - `src/locales/en.json` を更新。
3. マージコミットを作成してプッシュ:
   ```bash
   git commit -m "chore(sync): resolve upstream merge conflicts"
   git push origin i18n-core
   ```
4. 以降は **シナリオ A の Step 2 〜 Step 3** と同様に `l10n-ja` の日本語辞書更新 ➔ `master` への CalVer リリースを実施。

---

## ⚠️ 重要な注意事項
- **upstream ワークフローの不可侵**: upstream のマージによって `.github/workflows/` に本家専用ファイルが追加された場合でも直接削除せず、`docs/ci-workflow-guidelines.md` に従って `gh workflow disable` で停止してください。
- **過剰テストの防止**: CIを高速（1分以内）に維持するため、日常の自動CIには重い単体テストを含めません。
