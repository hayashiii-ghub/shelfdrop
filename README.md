<p align="center">
  <img src="Assets/DopaGak.png" width="160" alt="DOPA-GAK! app icon">
</p>

<h1 align="center">DOPA-GAK!</h1>

<p align="center">
  ファイル棚を、懐かしい携帯デバイスの操作感と触覚で扱うmacOSアプリ。
</p>

<p align="center">
  <a href="https://github.com/hayashiii-ghub/shelfdrop/releases/latest"><img src="https://img.shields.io/github/v/release/hayashiii-ghub/shelfdrop?display_name=tag&sort=semver" alt="Latest release"></a>
  <a href="https://github.com/hayashiii-ghub/shelfdrop/actions/workflows/ci.yml"><img src="https://github.com/hayashiii-ghub/shelfdrop/actions/workflows/ci.yml/badge.svg" alt="CI status"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-black" alt="macOS 14 or later">
  <img src="https://img.shields.io/badge/Swift-5.9%2B-F05138" alt="Swift 5.9 or later">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="MIT License"></a>
</p>

<p align="center">
  <a href="https://shelfdrop-gamma.vercel.app"><strong>Webサイト</strong></a>
  ・
  <a href="https://github.com/hayashiii-ghub/shelfdrop/releases/latest/download/DopaGak-macos.dmg"><strong>最新版をダウンロード</strong></a>
  ・
  <a href="https://github.com/hayashiii-ghub/shelfdrop/issues">Issue</a>
</p>

## DOPA-GAK!とは

DOPA-GAK!は、作業中のファイルを一時的にまとめるShelfを、触覚付きの携帯デバイス型UIで扱うmacOSアプリです。KURUKURUのクリックホイールと、POCHITTOのスケルトン携帯機型コントロールから好きなDeviceを選べます。画面はどちらもShelfだけを表示し、擬似OSの別アプリやサウンド再生は持ちません。

造形とフィードバックの基準は[DESIGN.md](DESIGN.md)にまとめています。

Apple IDやMac App Storeを使わず、GitHub Releasesから直接ダウンロードできます。Apple Silicon MacとIntel Macの両方に対応しています。

## 主な機能

| 機能 | 操作 |
| --- | --- |
| Finderの選択項目を追加 | Finderで選択して`Option + Tab` |
| 棚の表示・非表示を切り替える | `Option + Shift + Tab` |
| コピー中のテキストを保存 | メニューバーの`Add Clipboard Text`、またはPOCHITTOの`SELECT` |
| 複数項目をまとめて取り出す | 2つ以上のファイルがある時に画面ヘッダーへ出るスタックアイコンをドラッグ |
| 項目を個別に取り出す | 棚の行をFinderや他のアプリへドラッグ |
| コピー・移動・ZIP化 | メニューバーから実行 |
| 開く・Finderで表示・コピー・削除 | 右ペインのボタン、または行のコンテキストメニュー |
| 項目を選ぶ | ホイール、トラックパッド、マウスホイール、D-pad上下、またはキーボード上下 |
| 棚を移動 | 筐体上端をドラッグ |
| 棚を隠す | `MENU`、`B`、左矢印、`Escape`、またはグローバルショートカット |
| Deviceを切り替える | メニューバーの`Controls` |

棚は表示後、閉じるまでほかのウィンドウより手前に残ります。棚内でのファイル名変更や並べ替えは行いません。

## 対応する項目

- 通常のファイルとフォルダ
- CSV、TXT、Markdown、HTML、JSON、PDF、SVG
- PNG、JPEGなどの画像
- 独自拡張子や拡張子のないファイル
- URLとプレーンテキスト

クリップボードは自動監視しません。保存したいテキストをコピーした後、メニューバーの`Add Clipboard Text`またはPOCHITTOの`SELECT`を明示的に実行した時だけ追加します。

ファイル拡張子による制限は設けていません。アプリからファイル本体のデータだけが渡された場合も、元のファイル名と拡張子を保って一時保存します。

## インストール

### DMGからインストール

1. [最新の`DopaGak-macos.dmg`をダウンロード](https://github.com/hayashiii-ghub/shelfdrop/releases/latest/download/DopaGak-macos.dmg)します。
2. DMGを開き、`DopaGak.app`を`Applications`へドラッグします。
3. `Applications`フォルダから`DopaGak.app`を開きます。

### ターミナルからインストール/更新

```sh
curl -fsSL https://github.com/hayashiii-ghub/shelfdrop/releases/latest/download/install_latest.sh | bash
```

既存の`/Applications/DopaGak.app`または`~/Applications/DopaGak.app`を検出して最新版に入れ替えます。まだ入っていない場合は、書き込み可能なら`/Applications`、そうでなければ`~/Applications`にインストールします。

> [!NOTE]
> Apple Developer Program未登録のため、現在の配布版はad hoc署名です。初回起動時にmacOSの警告が表示される場合があります。

## 更新

ターミナルから最新版へ入れ替える場合は、インストールと同じコマンドを使います。

```sh
curl -fsSL https://github.com/hayashiii-ghub/shelfdrop/releases/latest/download/install_latest.sh | bash
```

`/Applications`または`~/Applications`にある既存の`DopaGak.app`を検出して更新します。メニューバーの`Download Latest Version...`から最新版のダウンロードを開始することもできます。

## 権限

`Option + Tab`でFinderの選択項目を取得するため、初回利用時にmacOSからFinderの操作許可を求められます。Finderのファイルとフォルダは`Option + Tab`で追加し、リンク・画像・テキストはドラッグ＆ドロップでも追加できます。

## 開発

必要な環境:

- macOS 14以降
- Xcode Command Line Tools
- Swift 5.9以降

ビルドして起動:

```sh
./script/build_and_run.sh
```

テストとスクリプト検証:

```sh
make check
```

配布用DMGとZIPを作成:

```sh
make package VERSION=v0.3.3
```

Release workflowでnotarized buildを作成するには、GitHub Secretsに`APPLE_DEVELOPER_ID_CERTIFICATE_BASE64`、`APPLE_DEVELOPER_ID_CERTIFICATE_PASSWORD`、`APPLE_NOTARY_KEY_BASE64`、`APPLE_NOTARY_KEY_ID`、`APPLE_NOTARY_ISSUER_ID`を設定します。

主なディレクトリ:

```text
Sources/ShelfDrop/    アプリ本体
Tests/ShelfDropTests/ テスト
Assets/               アプリ・メニューバーアイコン
script/               ビルド、配布、更新スクリプト
```

## コントリビューション

バグ報告と機能提案は[Issues](https://github.com/hayashiii-ghub/shelfdrop/issues)から受け付けています。Pull Requestを送る前に[CONTRIBUTING.md](CONTRIBUTING.md)を確認してください。

セキュリティ上の問題は公開Issueへ詳細を書かず、[SECURITY.md](SECURITY.md)の手順で報告してください。

## ライセンス

[MIT License](LICENSE)
