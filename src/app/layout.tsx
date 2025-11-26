import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'bloom2',
  description: 'Built with OmniForge',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
