import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "NEONFALL: XENO HUNT // MADCROOS",
  description: "Kaçılabilir düşman saldırıları, faz dash sistemi ve derin koşu yükseltmeleriyle yenilenen NEONFALL Web sürümü.",
  icons: {
    icon: "/favicon.svg",
    shortcut: "/favicon.svg",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="tr">
      <body className="antialiased">{children}</body>
    </html>
  );
}
