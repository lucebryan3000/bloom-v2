export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export default function Custom404() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-4 p-8">
      <h1 className="text-3xl font-semibold">404 - Page Not Found</h1>
      <p className="text-muted-foreground">This page does not exist.</p>
    </main>
  );
}
