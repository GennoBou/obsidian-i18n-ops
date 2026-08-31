# Google Jules 指示書: 差分日本語翻訳タスク (`src/locales/ja.json`)

この指示書は、GitHub Actions (`upstream-sync`) によって起票された Issue（`[Jules Sync]`）を元に、Google Jules が `src/locales/ja.json` に不足している日本語訳を追加し、Pull Request を作成するための安全な手順書です。

---

## 🎯 タスクの目的
`src/locales/en.json`（ベース英語辞書）に新しく追加されたキーを検出し、公式用語集・スタイルガイドに従って `src/locales/ja.json` に自然な日本語訳を追加・検証して `l10n-ja` ブランチへの Pull Request を作成すること。
（※ PRマージ後、変更は `l10n-ja` ➔ `feat-localize` ➔ `master` へと順次マージリレーされます）

---

## ⛔ 絶対禁止事項（CRITICAL RULES）
- **既存ファイルの削除やブランチ初期化の禁止**:
  - `.github/workflows/` 内のファイル、`manifest.json`、`package.json` などを削除したり、upstream（本家）のコードで上書きしてはなりません。
- **Git の破壊的操作の禁止**:
  - `git reset --hard` や upstream ブランチの直接チェックアウトによるフォーク独自ファイルの破棄を行ってはなりません。

---

## 📚 参照リソース（用語集・スタイルガイド）
翻訳時は必ず以下の中央用語集・ルールを参照してください：
- **Obsidian 公式UI標準用語集**: [glossary/obsidian-ja.json](https://raw.githubusercontent.com/GennoBou/obsidian-i18n-ops/main/glossary/obsidian-ja.json)
- **スタイルガイド & 翻訳ルール**: [glossary/I18N.md](https://raw.githubusercontent.com/GennoBou/obsidian-i18n-ops/main/glossary/I18N.md)

---

## 🛠️ 実行手順

### Step 1: 未翻訳キーの検出
1. 現在の辞書整合性を検証し、不足しているキーを確認します:
   ```bash
   node scripts/check-i18n.mjs # または npm run check-i18n
   ```
2. `src/locales/en.json` に存在し、`src/locales/ja.json` に存在しないキーを特定します。

### Step 2: `src/locales/ja.json` への翻訳追加
1. `glossary/obsidian-ja.json` を参照し、Obsidian 公式 UI 用語（例: `Vault` ➔ `保管庫`, `Settings` ➔ `設定`）を正確に適用します。
2. **文体**: 簡潔で自然な日本語（「です・ます」調推奨）。
3. **プレースホルダーの厳密一致**: 原文に含まれる `{name}`, `{count}`, `{{DATE}}` などの変数は、翻訳文でも一切変更・削除せずそのまま配置します。
4. `src/locales/ja.json` にキーと日本語訳を追加して保存します。

### Step 3: 検証
1. 辞書検証スクリプトを再実行し、エラーおよび警告が 0 件であることを確認します:
   ```bash
   node scripts/check-i18n.mjs # または npm run check-i18n
   ```
2. 型チェックおよびビルドが正常に通ることを確認します:
   ```bash
   npm run check # (定義されている場合)
   npm run build
   ```

### Step 4: Pull Request の作成
1. 変更した `src/locales/ja.json`（必要に応じて `src/locales/en.json`）のみをコミットします。
2. 作業ブランチから Pull Request を作成して完了とします:
   - **PR タイトル**: `feat(l10n): add Japanese translations for upstream changes`
   - **PR 本文**: 追加した翻訳キーの要約と `npm run check-i18n` のパス結果を記載。
