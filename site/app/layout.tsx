import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({ variable: "--font-geist-sans", subsets: ["latin"] });
const geistMono = Geist_Mono({ variable: "--font-geist-mono", subsets: ["latin"] });

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
  return <html lang="ja"><body className={`${geistSans.variable} ${geistMono.variable}`}>{children}</body></html>;
}
