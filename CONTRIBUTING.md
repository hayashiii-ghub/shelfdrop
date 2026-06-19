# ShelfDropへのコントリビューション

ShelfDropへのバグ報告、機能提案、Pull Requestを歓迎します。

## Issue

- バグ報告では、ShelfDropとmacOSのバージョン、Macの種類、再現手順を記載してください。
- 機能提案では、追加したい操作だけでなく、解決したい作業上の問題を記載してください。
- セキュリティ上の問題は公開Issueに書かず、[SECURITY.md](SECURITY.md)を確認してください。
- 個人情報、アクセストークン、機密ファイルをログやスクリーンショットへ含めないでください。

## 開発手順

1. リポジトリをforkして、変更内容ごとにbranchを作成します。
2. 既存の構成とSwiftUI/AppKitの使い分けに合わせて実装します。
3. `make check`を実行します。
4. UI変更では、変更前後が分かるスクリーンショットをPull Requestへ添付します。
5. 変更内容、理由、検証結果をPull Requestへ記載します。

```sh
git clone https://github.com/<your-account>/shelfdrop.git
cd shelfdrop
make check
```

## Pull Requestの基準

- 1つのPull Requestは1つの目的に絞ってください。
- 無関係なリファクタリングやフォーマット変更を混ぜないでください。
- 新しい動作には、可能な範囲でテストを追加してください。
- macOS 14以降で動作するAPIを使用してください。
- 配布、署名、権限に影響する変更は、その影響を本文へ明記してください。

メンテナーは、プロジェクトの方向性や保守範囲に合わない提案を採用しない場合があります。
