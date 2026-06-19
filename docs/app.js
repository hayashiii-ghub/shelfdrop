// ShelfDrop landing page interactions.
// All motion is gated on prefers-reduced-motion. No scroll listeners are used:
// scroll-driven UI relies on IntersectionObserver only.

(function () {
  "use strict";

  // Mark JS as available so CSS can hide reveal elements only when we can show them.
  document.documentElement.classList.add("js");

  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var finePointer = window.matchMedia("(pointer: fine)").matches;

  // ---------------------------------------------------------------------------
  // i18n (EN / JA). Strings hold HTML so links, <code>, and <br> survive a swap.
  // Content is static and authored here, so innerHTML is safe.
  // ---------------------------------------------------------------------------
  var ZIP = "https://github.com/hayashiii-ghub/shelfdrop/releases/latest/download/ShelfDrop-macos.zip";

  var I18N = {
    en: {
      "meta.title": "ShelfDrop - A floating shelf for your Mac",
      "meta.desc": "ShelfDrop is a small floating shelf for macOS that holds files, folders, links, and text the moment you start dragging, then drops them wherever you need.",
      "skip": "Skip to content",
      "nav.features": "Features",
      "nav.how": "How it works",
      "cta.download": "Download for macOS",
      "cta.github": "View on GitHub",
      "hero.h1": "A floating shelf<br>for your Mac.",
      "hero.lede": "Park files, folders, links, and text the instant you start dragging, then drop them wherever you need them.",
      "trust.1": "Free and open source",
      "trust.2": "Direct download, no App Store",
      "trust.3": "Apple Silicon and Intel",
      "trust.4": "Built for macOS 14 and later",
      "feat.eyebrow": "What it does",
      "feat.h2": "Everything stays one shake away.",
      "feat.1.t": "Shake to summon",
      "feat.1.b": "Start dragging anything, give your cursor a quick shake, and the shelf slides in right where you are.",
      "feat.2.t": "Grab from Finder",
      "feat.2.b": "Select items in Finder and press Option and Tab to send them straight to the shelf.",
      "feat.3.t": "One task, one shelf",
      "feat.3.b": "Shelves stay above your windows. Shake again or press Option and Tab while one is open to create another independent shelf.",
      "feat.4.t": "Take one or take all",
      "feat.4.b": "Drag a single row out, or pull the whole stack at once from the footer.",
      "feat.5.t": "Drag out anywhere",
      "feat.5.b": "Drop items into any app or folder, exactly like dragging from Finder.",
      "feat.6.t": "Copy, move, or zip",
      "feat.6.b": "Act on everything on the shelf from the footer: copy somewhere, move it, or bundle it into a single zip.",
      "how.h2": "Three moves, no window juggling.",
      "step.1.t": "Drag",
      "step.1.b": "Start dragging any files, from Finder or any other app.",
      "step.2.t": "Shake",
      "step.2.b": "Wiggle your cursor. The shelf appears and you drop everything in.",
      "step.3.t": "Drop",
      "step.3.b": "Later, drag items out to their destination, one by one or all together.",
      "sup.h2": "No file-type limits.",
      "sup.sub": "If you can drag it, the shelf can hold it.",
      "chip.files": "Files",
      "chip.folders": "Folders",
      "chip.images": "Images (PNG, JPEG)",
      "chip.text": "Plain text",
      "chip.urls": "URLs",
      "chip.noext": "No-extension files",
      "chip.custom": "Custom extensions",
      "inst.eyebrow": "Get started",
      "inst.h2": "Up and running in a minute.",
      "inst.s1": '<a href="' + ZIP + '">Download the latest <code>ShelfDrop-macos.zip</code></a>.',
      "inst.s2": "Unzip it and move <code>ShelfDrop.app</code> into Applications.",
      "inst.s3": "On first launch, Control-click the app and choose Open.",
      "note.title": "First-launch warning",
      "note.p1": 'Builds are ad-hoc signed, not notarized, so macOS may warn the first time. If you see "ShelfDrop is damaged," clear the quarantine flag:',
      "note.foot": "Already installed? Update from the terminal:",
      "final.h2": "Keep your next drop one shake away.",
      "foot.releases": "Releases",
      "foot.issue": "Report an issue",
      "foot.mit": "MIT License",
      "foot.apple": "Not affiliated with Apple Inc."
    },
    ja: {
      "meta.title": "ShelfDrop - Mac のためのフローティングシェルフ",
      "meta.desc": "ShelfDrop は macOS 用の小さなフローティングシェルフです。ドラッグした瞬間にファイル・フォルダ・リンク・テキストを一時的に置いて、必要な場所へそのままドロップできます。",
      "skip": "本文へスキップ",
      "nav.features": "機能",
      "nav.how": "使い方",
      "cta.download": "macOS 版をダウンロード",
      "cta.github": "GitHub で見る",
      "hero.h1": "Mac のための<br>フローティングシェルフ。",
      "hero.lede": "ドラッグした瞬間にファイル・フォルダ・リンク・テキストを一時的に置いて、必要な場所へそのままドロップ。",
      "trust.1": "無料・オープンソース",
      "trust.2": "App Store 不要、直接ダウンロード",
      "trust.3": "Apple Silicon と Intel に対応",
      "trust.4": "macOS 14 以降に対応",
      "feat.eyebrow": "できること",
      "feat.h2": "ひと振りで、すべてが手の届く場所に。",
      "feat.1.t": "振って呼び出す",
      "feat.1.b": "何かをドラッグした状態でカーソルを軽く振ると、棚がその場にスッと現れます。",
      "feat.2.t": "Finder から取り込む",
      "feat.2.b": "Finder で項目を選び、Option + Tab で棚へそのまま送れます。",
      "feat.3.t": "作業ごとに、別の棚",
      "feat.3.b": "棚は閉じるまで手前に残ります。表示中にもう一度振るか Option + Tab を押すと、独立した別の棚を開けます。",
      "feat.4.t": "1つでも、まとめても",
      "feat.4.b": "行を1つずつドラッグしても、フッターからまとめて引き出してもかまいません。",
      "feat.5.t": "どこへでもドラッグ",
      "feat.5.b": "Finder からのドラッグと同じ感覚で、どのアプリやフォルダにもドロップできます。",
      "feat.6.t": "コピー・移動・ZIP化",
      "feat.6.b": "棚の中身をフッターから一括操作。任意の場所へコピー、移動、または1つの ZIP にまとめられます。",
      "how.h2": "3ステップ、ウィンドウの行き来なし。",
      "step.1.t": "ドラッグ",
      "step.1.b": "Finder でも他のアプリでも、ファイルのドラッグを始めます。",
      "step.2.t": "振る",
      "step.2.b": "カーソルを振ると棚が現れるので、そこにまとめてドロップ。",
      "step.3.t": "ドロップ",
      "step.3.b": "あとで、目的の場所へ項目をドラッグ。1つずつでも、まとめてでも。",
      "sup.h2": "ファイル形式の制限なし。",
      "sup.sub": "ドラッグできるものなら、棚に置けます。",
      "chip.files": "ファイル",
      "chip.folders": "フォルダ",
      "chip.images": "画像 (PNG, JPEG)",
      "chip.text": "プレーンテキスト",
      "chip.urls": "URL",
      "chip.noext": "拡張子なしのファイル",
      "chip.custom": "独自拡張子",
      "inst.eyebrow": "はじめる",
      "inst.h2": "1分で使い始められます。",
      "inst.s1": '最新の <a href="' + ZIP + '"><code>ShelfDrop-macos.zip</code></a> をダウンロードします。',
      "inst.s2": "展開して <code>ShelfDrop.app</code> を「アプリケーション」へ移動します。",
      "inst.s3": "初回起動時は、アプリを Control キーを押しながらクリックして「開く」を選びます。",
      "note.title": "初回起動の警告について",
      "note.p1": "ビルドは ad hoc 署名で notarize していないため、初回起動時に macOS が警告することがあります。「ShelfDrop は壊れているため開けません」と表示されたら、検疫フラグを外してください:",
      "note.foot": "すでにインストール済みなら、ターミナルから更新できます:",
      "final.h2": "次のドロップを、ひと振りの距離に。",
      "foot.releases": "リリース",
      "foot.issue": "問題を報告",
      "foot.mit": "MIT ライセンス",
      "foot.apple": "Apple Inc. とは関係ありません。"
    }
  };

  var STORE_KEY = "shelfdrop-lang";
  var nodes = document.querySelectorAll("[data-i18n]");
  var metaNodes = document.querySelectorAll("[data-i18n-meta]");
  var toggleBtns = document.querySelectorAll(".lang-toggle button");

  function applyLang(lang) {
    if (!I18N[lang]) lang = "en";
    var dict = I18N[lang];

    document.documentElement.lang = lang;
    if (dict["meta.title"]) document.title = dict["meta.title"];

    nodes.forEach(function (el) {
      var key = el.getAttribute("data-i18n");
      if (dict[key] != null) el.innerHTML = dict[key];
    });
    metaNodes.forEach(function (el) {
      var key = "meta." + el.getAttribute("data-i18n-meta");
      if (dict[key] != null) el.setAttribute("content", dict[key]);
    });
    toggleBtns.forEach(function (btn) {
      btn.setAttribute("aria-pressed", String(btn.getAttribute("data-lang") === lang));
    });

    try { localStorage.setItem(STORE_KEY, lang); } catch (e) {}
  }

  function initialLang() {
    var saved;
    try { saved = localStorage.getItem(STORE_KEY); } catch (e) {}
    // Default to English; honor a previously chosen language if one is stored.
    return (saved && I18N[saved]) ? saved : "en";
  }

  toggleBtns.forEach(function (btn) {
    btn.addEventListener("click", function () {
      applyLang(btn.getAttribute("data-lang"));
    });
  });

  applyLang(initialLang());

  // ---------------------------------------------------------------------------
  // Scroll-reveal (IntersectionObserver, not a scroll listener)
  // ---------------------------------------------------------------------------
  // Stagger grouped reveals so cells/steps cascade in rather than popping together.
  if (!reduceMotion) {
    document.querySelectorAll(".bento .cell").forEach(function (el, i) {
      el.style.transitionDelay = (i * 0.07).toFixed(2) + "s";
    });
    document.querySelectorAll(".steps .step").forEach(function (el, i) {
      el.style.transitionDelay = (i * 0.09).toFixed(2) + "s";
    });
  }

  var reveals = document.querySelectorAll(".reveal");
  if (reduceMotion || !("IntersectionObserver" in window)) {
    reveals.forEach(function (el) { el.classList.add("in"); });
  } else {
    var revealObserver = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add("in");
          revealObserver.unobserve(entry.target);
        }
      });
    }, { threshold: 0.15, rootMargin: "0px 0px -8% 0px" });
    reveals.forEach(function (el) { revealObserver.observe(el); });
  }

  // ---------------------------------------------------------------------------
  // Nav background toggle via a top sentinel (no scroll listener)
  // ---------------------------------------------------------------------------
  var nav = document.getElementById("nav");
  var sentinel = document.getElementById("top-sentinel");
  if (nav && sentinel && "IntersectionObserver" in window) {
    var navObserver = new IntersectionObserver(function (entries) {
      nav.classList.toggle("scrolled", !entries[0].isIntersecting);
    }, { threshold: 0 });
    navObserver.observe(sentinel);
  }

  // ---------------------------------------------------------------------------
  // Pointer-tracked specular highlight on glass surfaces
  // ---------------------------------------------------------------------------
  if (finePointer && !reduceMotion) {
    document.querySelectorAll(".glass").forEach(function (el) {
      var queued = false, lastX = 50, lastY = 0;
      el.addEventListener("pointermove", function (e) {
        var rect = el.getBoundingClientRect();
        lastX = ((e.clientX - rect.left) / rect.width) * 100;
        lastY = ((e.clientY - rect.top) / rect.height) * 100;
        if (!queued) {
          queued = true;
          requestAnimationFrame(function () {
            el.style.setProperty("--mx", lastX + "%");
            el.style.setProperty("--my", lastY + "%");
            queued = false;
          });
        }
      });
      el.addEventListener("pointerleave", function () {
        el.style.setProperty("--mx", "50%");
        el.style.setProperty("--my", "-10%");
      });
    });

    // Hero icon parallax tilt: the .hero-art container rotates toward the cursor
    // while the icon inside keeps floating (separate elements, no transform clash).
    var hero = document.querySelector(".hero");
    var heroArt = document.querySelector(".hero-art");
    if (hero && heroArt) {
      var tiltQueued = false, tiltX = 0, tiltY = 0;
      hero.addEventListener("pointermove", function (e) {
        var r = hero.getBoundingClientRect();
        tiltY = ((e.clientX - r.left) / r.width - 0.5) * 16;
        tiltX = -((e.clientY - r.top) / r.height - 0.5) * 16;
        if (!tiltQueued) {
          tiltQueued = true;
          requestAnimationFrame(function () {
            heroArt.style.transform =
              "perspective(900px) rotateX(" + tiltX.toFixed(2) + "deg) rotateY(" + tiltY.toFixed(2) + "deg)";
            tiltQueued = false;
          });
        }
      });
      hero.addEventListener("pointerleave", function () { heroArt.style.transform = ""; });
    }
  }

  // ---------------------------------------------------------------------------
  // Copy-to-clipboard buttons on code blocks
  // ---------------------------------------------------------------------------
  document.querySelectorAll(".copy-btn").forEach(function (btn) {
    btn.addEventListener("click", function () {
      var block = btn.closest(".code-block");
      var code = block ? block.querySelector("code") : null;
      if (!code || !navigator.clipboard) return;
      navigator.clipboard.writeText(code.textContent.trim()).then(function () {
        var icon = btn.querySelector("i");
        btn.classList.add("copied");
        if (icon) icon.className = "ph ph-check";
        setTimeout(function () {
          btn.classList.remove("copied");
          if (icon) icon.className = "ph ph-copy";
        }, 1600);
      });
    });
  });
})();
