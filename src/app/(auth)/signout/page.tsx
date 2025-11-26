import { signOut } from "@/lib/auth";

export default function SignOutPage() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="w-full max-w-md space-y-8 rounded-lg border p-8 shadow-sm">
        <div className="text-center">
          <h1 className="text-2xl font-bold">Sign Out</h1>
          <p className="mt-2 text-sm text-muted-foreground">
            Are you sure you want to sign out?
          </p>
        </div>
        <form
          action={async () => {
            "use server";
            await signOut({ redirectTo: "/" });
          }}
        >
          <button
            type="submit"
            className="w-full rounded-md bg-destructive px-4 py-2 text-destructive-foreground hover:bg-destructive/90"
          >
            Sign Out
          </button>
        </form>
      </div>
    </div>
  );
}
