"use client";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export default function GlobalError({ error }: { error: Error }) {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-4 p-8">
      <h1 className="text-3xl font-semibold">Something went wrong</h1>
      <p className="text-muted-foreground">{error.message || "Unexpected error"}</p>
    </main>
  );
}
