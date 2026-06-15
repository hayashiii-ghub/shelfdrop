# ShelfDrop

ShelfDrop は、Dropover のように使える小さな macOS 用シェルフアプリです。ファイルをドラッグしている時だけフローティングの棚を開き、ファイルやフォルダを一時的に置いたり、コピー、移動、ZIP 化、再ドラッグできます。

## 動作環境

- macOS 14 以降
- Xcode Command Line Tools
- Swift 5.9 以降

## ビルドして起動

```sh
./script/build_and_run.sh
```

このスクリプトは SwiftPM ターゲットをビルドし、`dist/ShelfDrop.app` を作成して、起動中の ShelfDrop を停止した上で新しいアプリを起動します。

コンパイルだけ確認する場合:

```sh
swift build
```

## 別の Mac で使う

GitHub Releases から `ShelfDrop-macos.zip` をダウンロードしてください。

[最新版をダウンロード](https://github.com/hayashiii-ghub/shelfdrop/releases/latest/download/ShelfDrop-macos.zip)

ダウンロードした zip を展開し、`ShelfDrop.app` を開きます。

GitHub Release のビルドは Apple Silicon Mac と Intel Mac の両方に対応した universal アプリです。

このアプリは Apple Developer ID での署名や notarization をしていないため、初回起動時に macOS Gatekeeper に止められることがあります。その場合は Finder で次の手順を使ってください。

1. `ShelfDrop.app` を Control キーを押しながらクリックします。
2. `開く` を選びます。
3. 警告ダイアログでもう一度 `開く` を選びます。

それでも「壊れているため開けません」のように表示される場合は、quarantine 属性を削除します。

```sh
xattr -dr com.apple.quarantine /Applications/ShelfDrop.app
```

`/Applications` 以外に置いた場合は、実際のアプリのパスに置き換えてください。

## 配布用 zip をローカルで作る

```sh
./script/package.sh
```

作成されるファイル:

```text
dist/ShelfDrop-macos.zip
```

フル版 Xcode が入っている環境では、Apple Silicon Mac と Intel Mac の両方に対応した universal アプリを作成します。Xcode Command Line Tools だけの環境では、その Mac のアーキテクチャ向けに作成します。

## GitHub Release を作る

バージョンタグを push すると、GitHub Actions が `ShelfDrop-macos.zip` をビルドして GitHub Releases にアップロードします。

```sh
git tag v0.1.1
git push origin v0.1.1
```

## メモ

- 棚はファイルのドラッグ中だけ開きます。通常のカーソル操作やシェイクでは開きません。
- ヘッダー部分をドラッグすると、事前クリックなしで棚を移動できます。
- `.gitignore` により、ビルド生成物は Git 管理から除外しています。
