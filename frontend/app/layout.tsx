import "./globals.css";
import type { Metadata } from "next";
import Nav from "@/components/Nav";

export const metadata: Metadata = {
  title: "VetLink Africa",
  description: "Better Connections. Better Animal Care.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <header className="mx-auto flex max-w-4xl items-center justify-between px-5 py-4">
          <a href="/animals" className="text-xl font-extrabold">VetLink<span className="text-leaf"> Africa</span></a>
          <Nav />
        </header>
        <main className="mx-auto max-w-4xl px-5 pb-16">{children}</main>
      </body>
    </html>
  );
}
