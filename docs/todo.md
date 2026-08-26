# obsidian-i18n-ops 今後の検討・検証課題 (Backlog / Roadmap)

## 1. GitHub Actions CI の実行時間最適化 【完了】
- **解決方針**: 4象限分類マトリクス（本家専用無効化、重厚テスト無効化、多言語化高速CI新設、BRATリリース新設）を策定。
- **成果物**:
  - [docs/ci-workflow-guidelines.md](ci-workflow-guidelines.md) に汎用判断基準・分類ルールを文書化。
  - [`templates/i18n-ci.yml`](../templates/i18n-ci.yml)（パッケージマネージャ自動判別・高速CI）を新設。
  - [`templates/brat-release.yml`](../templates/brat-release.yml)（CSS有無不問のBRAT専用CalVerリリース）を新設。
  - QuickAddにて `check-i18n`、`check`、`build-with-lint`、単体テストの正常動作を確認。

---

## 2. GitHub Actions による upstream 更新チェック＆自動マージの検証 【完了】
- **解決方針**:
  - `templates/upstream-sync.yml` に 3層ブランチ（`i18n-core` ➔ `l10n-ja` ➔ `master`）の自動マージ、CalVer（`YY.M.D[.N]`）自動計算、タグ発行、未翻訳キー/コンフリクト検知時の安全なIssue通知パイプラインを実装。
- **成果物**:
  - [`templates/upstream-sync.yml`](../templates/upstream-sync.yml)（汎用自動同期＆自動マージ・自動リリース）
  - QuickAddリポジトリ（`.github/workflows/upstream-sync.yml`）に適用。

---

## 3. Google Jules を活用した自動翻訳・コンフリクト解消パイプラインの構築
- **現状**: upstream の更新によって新しい UI 文字列が追加された場合や、コードコンフリクトが発生した場合は、workflow 単体では解決できない。
- **課題**:
  - workflow で「新しい翻訳キーの検出」または「コンフリクト発生」を検知した際に、自動で Issue や PR を作成、または Google Jules（エージェント）にタスクを渡して以下の処理を実行させる仕組みを設計・検証する:
    1. upstream の変更を `i18n-core` にマージし、新しい英語文字列を `t()` 化して `en.json` を更新。
    2. `l10n-ja` ブランチで用語集（`glossary/obsidian-ja.json`）を参照して `ja.json` に日本語訳を追加・更新。
    3. `master` にマージして PR を作成（または自動マージ＆リリース）。
