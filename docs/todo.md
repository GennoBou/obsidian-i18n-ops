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

## 3. Google Jules を活用した自動翻訳・コンフリクト解消パイプラインの構築 【完了】
- **解決方針**:
  - `templates/upstream-sync.yml` において、コンフリクト時や未翻訳キー検出時に、Google Jules がそのまま読み込んでタスクを実行できる指示・リンク付き GitHub Issue（`[Jules Sync]`）を自動起票する仕組みを実装。
  - [`prompts/jules-sync.md`](../prompts/jules-sync.md) を、新規キー翻訳モードとコンフリクト解消モードの2系統で完全手順化した高精度プロンプトへ刷新。
- **成果物**:
  - [`prompts/jules-sync.md`](../prompts/jules-sync.md)
  - [`templates/upstream-sync.yml`](../templates/upstream-sync.yml) 内の Issue テンプレート連携スクリプト

