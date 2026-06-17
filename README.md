# ShelfDrop

ShelfDrop は、Dropover のように使える小さな macOS 用シェルフアプリです。ファイルのドラッグ中や Finder のショートカット操作でフローティングの棚を開き、ファイルやフォルダを一時的に置いたり、コピー、移動、ZIP 化、再ドラッグできます。

## できること

### ドラッグ中だけ棚を表示

ファイルをドラッグしている時だけ、画面上に小さなフローティング棚を表示します。通常のカーソル移動やシェイクでは表示されません。

### ファイルを一時的に置く

ドラッグ中のファイル、フォルダ、画像、リンク、テキストを棚に入れて、一時的に保持できます。複数の項目をまとめて置くこともできます。

### Finder の選択項目をショートカットで追加

Finder でファイルやフォルダを選択して `Option + Tab` を押すと、ドラッグせずに選択項目を棚へ直接追加して表示できます。複数選択にも対応しています。

初回実行時は、macOS から Finder の操作許可を求められます。許可すると、それ以降はショートカットから選択項目を取得できます。

### 対応している形式

Finder からドラッグする通常のファイルやフォルダに対応しています。画像データとして渡される場合は、PNG、TIFF、JPEG、GIF、HEIC、HEIF、SVG、WebP に対応しています。Markdown と HTML は、ファイルまたは文書データとして棚に入れられます。

### 棚から取り出す

棚に入れた項目は、もう一度ドラッグして Finder や他のアプリへ取り出せます。

### 開く・Finder で表示・コピーする

棚の項目は、その場で開いたり、Finder 上の場所を表示したり、クリップボードへコピーできます。

### まとめてコピー・移動・ZIP 化する

棚に入っている項目を、指定したフォルダへまとめてコピーまたは移動できます。まとめて ZIP ファイルにすることもできます。不要になった項目はまとめてクリアできます。

### メニューバーから操作する

メニューバーの ShelfDrop アイコンから、Finder の選択項目追加、棚の表示、クリア、アプリ終了を実行できます。

### 棚を移動・非表示にする

棚はほかのウィンドウより前面に表示され、外側をクリックしたりカーソルを離したりしても消えません。棚のヘッダー部分をドラッグすると、事前クリックなしで移動できます。`×` ボタン、または棚を操作中の Escape キーで非表示にできます。

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

## 更新する

すでに ShelfDrop を入れている Mac では、次のコマンドで最新版をダウンロードして入れ替えできます。

```sh
curl -fsSL https://raw.githubusercontent.com/hayashiii-ghub/shelfdrop/main/script/install_latest.sh | bash
```

既存の `ShelfDrop.app` が `/Applications` にある場合は、そこに上書きします。`~/Applications` にある場合は、そちらを更新します。どちらにもない場合は、書き込み可能なら `/Applications`、そうでなければ `~/Applications` にインストールします。

アプリのメニューバーから `Download Latest Version...` を選ぶと、最新版 zip のダウンロードも開始できます。

## ターミナルで管理する

よく使う操作は `make` から実行できます。

```sh
make build
make check
make run
make package
make install-latest
make release VERSION=v0.1.6
make status
```

`make check` は Swift のテストとシェルスクリプトの構文確認を実行します。`make release VERSION=...` は、タグを作って `main` とタグを GitHub に push します。タグ push 後、GitHub Actions が配布用 zip を作成します。

`main` への push と Pull Request では GitHub Actions の CI が自動実行されます。

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
git tag v0.1.6
git push origin v0.1.6
```

## メモ

- 棚はファイルのドラッグ中だけ開きます。通常のカーソル操作やシェイクでは開きません。
- Finder で項目を選択して `Option + Tab` を押すと、ドラッグせず棚へ追加できます。
- 表示した棚は外側クリックでは消えず、`×` ボタンで非表示にできます。
- ヘッダー部分をドラッグすると、事前クリックなしで棚を移動できます。
- `.gitignore` により、ビルド生成物は Git 管理から除外しています。
