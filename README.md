# obsidian-i18n-ops

英語のみに対応しているObsidianプラグインを多言語化（日本語化）し、GitHub Actions + Google Jules / Antigravity によって継続的・自動的にアップデートを追従するための汎用運用基盤リポジトリです。

---

## 🎯 目的と特徴

- **完全な汎用基盤**: 特定のプラグインに依存せず、任意のObsidianプラグインに適用可能。
- **原文キー方式（Raw Key Approach）**: `t("Original English Text")` を採用し、Zero-dependencyの薄いi18nアダプター（`templates/i18n.ts`）で動作。
- **決定論的CIチェック**: `scripts/check-i18n.ts` により、キー過不足や `{placeholder}` の整合性を自動検証。
- **自動追従パイプライン**: upstreamの更新を検知し、AI（Google Jules / Antigravity）による差分翻訳とGitHub Actionsの自動検証を連携。
- **BRAT対応**: フォーク版プラグインは個人用・コミュニティ検証用として **Obsidian42 - BRAT** 経由で導入可能。

---

## 📁 ディレクトリ構成

```
obsidian-i18n-ops/
├── .github/workflows/
│   └── reusable-upstream-sync.yml  # 再利用可能GitHub Actionsワークフロー
├── glossary/                       # 汎用対訳集・翻訳ルール
│   ├── obsidian-ja.json            # Obsidian公式UI標準用語集
│   └── I18N.md                     # スタイルガイド & 翻訳ルール
├── templates/                      # プラグイン配置用テンプレート
│   ├── i18n.ts                     # 軽量i18nアダプター（Zero-dependency）
│   └── upstream-sync.yml           # プラグイン用CI設定テンプレート
├── scripts/                        # 検証スクリプト
│   └── check-i18n.ts               # 辞書・プレースホルダー検証スクリプト
├── prompts/                        # AI指示書
│   ├── antigravity-init.md         # 初回全コードi18n化用指示書（Antigravity用）
│   └── jules-sync.md               # 日々の差分同期用指示書（Google Jules用）
└── docs/                           # 設計書および検討履歴
```

---

## 🚀 プラグインへの適用手順

任意の英語プラグインを多言語化する際は、[prompts/antigravity-init.md](prompts/antigravity-init.md) を参照して以下の手順を実行します。

1. **フォーク作成 & クローン**:
   ```bash
   gh repo fork <UPSTREAM_REPO_URL> --clone
   ```
2. **README.md の更新**:
   冒頭にi18nフォーク版であることおよびBRAT利用案内を記載。
3. **i18n基盤の導入**:
   - `templates/i18n.ts` をプラグインの `src/i18n.ts` に配置。
   - `scripts/check-i18n.ts` を `scripts/check-i18n.ts` に配置。
4. **UI文言の `t()` 化 & 辞書生成**:
   - 設定タブ、モーダル、コマンド、通知メッセージ等を `t("...")` でラップ。
   - `src/locales/en.json` および `src/locales/ja.json` を生成。
5. **検証 & ビルド**:
   ```bash
   npm run check-i18n
   npm run build
   ```
6. **定期追従CIの設定**:
   - `templates/upstream-sync.yml` を `.github/workflows/upstream-sync.yml` に配置してプッシュ。
