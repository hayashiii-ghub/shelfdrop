import type { Metadata } from "next";
import { IBM_Plex_Mono, IBM_Plex_Sans_JP } from "next/font/google";
import "./globals.css";

const ibmPlexSansJP = IBM_Plex_Sans_JP({
  variable: "--font-ibm-plex-sans-jp",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  display: "swap",
});
const ibmPlexMono = IBM_Plex_Mono({
  variable: "--font-ibm-plex-mono",
  subsets: ["latin"],
  weight: ["400", "500", "600"],
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL("https://shelfdrop.haygsiiii.chatgpt.site"),
  title: "ShelfDrop — 作業中のもの、いったんここへ。",
  description: "ファイル、フォルダ、リンク、テキストを一時的に置いておける、macOS用フローティングシェルフ。",
  icons: { icon: "/shelfdrop-icon.png", shortcut: "/shelfdrop-icon.png", apple: "/shelfdrop-icon.png" },
  openGraph: {
    title: "ShelfDrop — 作業中のもの、いったんここへ。",
    description: "Finderの選択項目も、リンクも、テキストも。必要になる瞬間まで手元に置けるmacOS用フローティングシェルフ。",
    type: "website",
    locale: "ja_JP",
    images: [{ url: "/og.png", width: 1200, height: 630, alt: "ShelfDrop — 作業中のもの、いったんここへ。" }],
  },
  twitter: {
    card: "summary_large_image",
    title: "ShelfDrop — 作業中のもの、いったんここへ。",
    description: "必要になる瞬間まで手元に置ける、macOS用フローティングシェルフ。",
    images: ["/og.png"],
  },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="ja"><body className={`${ibmPlexSansJP.variable} ${ibmPlexMono.variable}`}>{children}</body></html>;
}
