const downloadUrl =
  "https://github.com/hayashiii-ghub/shelfdrop/releases/latest/download/ShelfDrop-macos.dmg";
const updateCommand =
  "curl -fsSL https://github.com/hayashiii-ghub/shelfdrop/releases/latest/download/install_latest.sh | bash";

const useCases = [
  {
    index: "01",
    title: "離れたフォルダへ、まとめて運ぶ",
    text: "Finderで選んだファイルを棚に置き、移動先を開いてから一度にドラッグ。ウィンドウを並べる必要はありません。",
  },
  {
    index: "02",
    title: "リンクやメモも、一緒に待機",
    text: "URL、画像、テキストもファイルと同じ棚へ。いま使わないけれど、数分後に必要なものを手元に残せます。",
  },
  {
    index: "03",
    title: "受け渡し前に、ひとまとめ",
    text: "棚の中身をコピー、移動、ZIP化。複数の素材をメールやチャットへ渡す直前の整理に使えます。",
  },
  {
    index: "04",
    title: "必要なあいだだけ、最前面に",
    text: "小さな棚はほかのウィンドウより手前に常駐。使い終えたら閉じて、ショートカットですぐ呼び戻せます。",
  },
];

const steps = [
  ["選ぶ", "Finderでファイルやフォルダを選択します。"],
  ["置く", "Option + Tabで、選択したものをShelfDropへ送ります。"],
  ["取り出す", "必要な場所へ、ひとつずつでもまとめてでもドラッグします。"],
];

export default function Home() {
  return (
    <main>
      <nav className="nav shell" aria-label="メインナビゲーション">
        <a className="brand" href="#top" aria-label="ShelfDrop トップへ">
          <img src="/shelfdrop-icon.png" alt="" width="32" height="32" />
          <span>ShelfDrop</span>
        </a>
        <div className="navLinks">
          <a href="#uses">できること</a>
          <a href="#how">使い方</a>
          <a href="#install">導入</a>
        </div>
        <a className="navCta" href={downloadUrl}>ダウンロード</a>
      </nav>

      <section className="hero shell" id="top">
        <div className="heroCopy">
          <p className="eyebrow">A floating shelf for macOS</p>
          <h1>作業中のもの、<br />いったんここへ。</h1>
          <p className="lead">
            ファイル、フォルダ、リンク、テキストを一時的に置いておける、
            小さなmacOS用フローティングシェルフ。
          </p>
          <div className="heroActions">
            <a className="button primary" href={downloadUrl}>最新版をダウンロード <span>↘</span></a>
            <a className="button secondary" href="https://github.com/hayashiii-ghub/shelfdrop">GitHubで見る</a>
          </div>
          <p className="requirements">macOS 26以降 · Apple Silicon / Intel · 無料・オープンソース</p>
        </div>

        <div className="productStage" aria-label="ShelfDropのアプリ画面イメージ">
          <div className="orb orbOne" />
          <div className="orb orbTwo" />
          <div className="shelfMock glass">
            <div className="mockHeader">
              <div className="mockBrand">
                <img src="/shelfdrop-icon.png" alt="" width="30" height="30" />
                <strong>ShelfDrop</strong>
              </div>
              <div className="mockControls"><span>×</span><span>⌄</span><span className="count">3</span></div>
            </div>
            <div className="mockItems">
              <div><span className="fileIcon">▧</span><span><strong>proposal.pdf</strong><small>2.4 MB</small></span><em>···</em></div>
              <div><span className="fileIcon">◇</span><span><strong>references</strong><small>フォルダ</small></span><em>···</em></div>
              <div><span className="fileIcon">↗</span><span><strong>Design notes</strong><small>リンク</small></span><em>···</em></div>
            </div>
            <div className="mockFooter"><span>⇧</span><span>▣</span><span>▢</span><span>⊞</span><span>⌑</span><span>⌫</span></div>
          </div>
          <div className="shortcutChip glass"><kbd>⌥</kbd><span>+</span><kbd>⇥</kbd><p>Finderから追加</p></div>
        </div>
      </section>

      <section className="statement">
        <div className="shell statementInner">
          <p>移動先を開くまで。</p><span />
          <p>送信する瞬間まで。</p><span />
          <p>あとで使う、その時まで。</p>
        </div>
      </section>

      <section className="section shell" id="uses">
        <div className="sectionIntro">
          <p className="eyebrow">One shelf, fewer detours</p>
          <h2>ウィンドウを行き来する<br />小さな手間をなくす。</h2>
          <p>作業の途中にあるものを、置き場所を決める前のままキープできます。</p>
        </div>
        <div className="useGrid">
          {useCases.map((item) => (
            <article className="useCard glass" key={item.index}>
              <span className="cardIndex">{item.index}</span>
              <div><h3>{item.title}</h3><p>{item.text}</p></div>
            </article>
          ))}
        </div>
      </section>

      <section className="section howSection" id="how">
        <div className="shell howGrid">
          <div className="sectionIntro stickyIntro">
            <p className="eyebrow">Three simple moves</p>
            <h2>選んで、置いて、<br />あとで取り出す。</h2>
            <p>ファイルの種類による制限はありません。リンクや画像、テキストは直接ドロップできます。</p>
          </div>
          <ol className="steps">
            {steps.map(([title, text], index) => (
              <li key={title}>
                <span className="stepNumber">{String(index + 1).padStart(2, "0")}</span>
                <div><h3>{title}</h3><p>{text}</p></div>
                {index === 1 && <div className="keys"><kbd>option</kbd><span>+</span><kbd>tab</kbd></div>}
              </li>
            ))}
          </ol>
        </div>
      </section>

      <section className="section shell" id="install">
        <div className="sectionIntro centered">
          <p className="eyebrow">Ready when you are</p>
          <h2>1分で、あなたのMacに。</h2>
          <p>App Storeやアカウント登録は不要です。GitHub Releasesから直接インストールできます。</p>
        </div>
        <div className="installGrid">
          <article className="installCard featured glass">
            <span className="method">おすすめ</span>
            <h3>DMGからインストール</h3>
            <ol>
              <li><span>1</span>最新版のDMGをダウンロード</li>
              <li><span>2</span>ShelfDropをApplicationsへドラッグ</li>
              <li><span>3</span>Applicationsから起動</li>
            </ol>
            <a className="button primary full" href={downloadUrl}>ShelfDropをダウンロード <span>↘</span></a>
          </article>
          <article className="installCard glass">
            <span className="method">ターミナル</span>
            <h3>コマンドで導入・更新</h3>
            <p>次のコマンドは、未導入ならインストール、導入済みなら最新版への更新を行います。</p>
            <div className="codeBlock"><code>{updateCommand}</code></div>
            <p className="microcopy">既存のアプリを検出し、安全に入れ替えてから自動で起動します。</p>
          </article>
        </div>
        <aside className="permissionNote">
          <span className="noteIcon">⌥</span>
          <div><strong>最初の一度だけ、Finderの操作を許可してください。</strong><p>Option + Tabで選択項目を取得するため、macOSから確認が表示されます。クリップボードは自動監視しません。</p></div>
        </aside>
      </section>

      <section className="section shell updateSection">
        <div className="updatePanel glass">
          <div>
            <p className="eyebrow">Stay current</p>
            <h2>更新も、いつもの一行で。</h2>
            <p>インストール時と同じコマンドをもう一度実行するか、メニューバーの「Download Latest Version...」から最新版を取得できます。</p>
          </div>
          <div className="updateCode"><span>Terminal</span><code>{updateCommand}</code></div>
        </div>
      </section>

      <footer className="footer shell">
        <div className="brand"><img src="/shelfdrop-icon.png" alt="" width="30" height="30" /><span>ShelfDrop</span></div>
        <p>置き場所を決める前の、小さな置き場所。</p>
        <div><a href="https://github.com/hayashiii-ghub/shelfdrop">GitHub</a><a href="https://github.com/hayashiii-ghub/shelfdrop/issues">Issue</a><a href={downloadUrl}>Download</a></div>
      </footer>
    </main>
  );
}
