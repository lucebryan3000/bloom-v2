Perfect, that path helps tie it all together.

You’ve basically got three steps in this pipeline:

1. **Design**: `_build/omni-landing-design-v3.html` (done in Canva)
2. **Codex pass 1**: turn that HTML into a typed `page.tsx` while keeping the UI
3. **Codex pass 2**: swap hard-coded text for manifest/log/container data

Here’s exactly how I’d do it with Codex now that the design lives at `_build/omni-landing-design-v3.html`.

---

## Step 1 – “Respect the design, just convert to TSX”

First prompt to Codex (no dynamic data yet):

```text
You are my implementation assistant.

Context:
- The final UI design for the OmniForge landing page lives at:
  - _build/omni-landing-design-v3.html
- It is static HTML + Tailwind and represents the EXACT layout and styling I want.
- This page will become the root route in a Next.js App Router app: src/app/page.tsx.

Task:
1) Read _build/omni-landing-design-v3.html.
2) Convert this HTML into a Next.js App Router page component:
   - File: src/app/page.tsx
   - TypeScript
   - Default export function HomePage()
   - Treat it as a **server component** (no “use client”).

Requirements:
- Preserve the existing structure and Tailwind classNames as closely as possible.
- Keep ALL content static for now (use the same sample text and numbers that appear in the HTML).
- Do not add any data-loading logic yet (no fs, no fetch, no manifest).
- Only make changes needed to:
  - wrap markup in a React component
  - fix any JSX syntax issues (class -> className, self-closing tags, etc.)

Output:
- The full src/app/page.tsx content, ready to be pasted into the repo.
```

That gets you a 1:1 TSX version of the design with zero data plumbing, so you can run `pnpm dev` and confirm it looks identical.

---

## Step 2 – Introduce a manifest-shaped data model (mocked)

Once TSX is stable, do a second prompt that layers in dynamic fields but still uses **mock data** (no file I/O):

```text
You are now going to refactor src/app/page.tsx to prepare for dynamic data.

Context:
- The current src/app/page.tsx was generated directly from:
  - _build/omni-landing-design-v3.html
- It is static JSX: all text values are hard-coded.

Goal:
Introduce a typed data model that mirrors the OmniForge manifest and container/log info, and replace static strings with fields from a mock object. Do NOT read files yet.

Data shape (use interfaces/types in TypeScript):

- Manifest:
  - deployedBy: string
  - omniVersion: string
  - generatedAt: string
  - profile: {
      key: string
      name: string
      tagline?: string
      description?: string
      mode?: "dev" | "prod" | "ci" | "minimal" | string
    }
  - stack: {
      runtime?: string
      db?: string
      auth?: string
      ai?: string
      jobs?: string
      logging?: string
      ui?: string
      state?: string
      exports?: string
      testing?: string
      quality?: string
    }
  - features: {
      authentication: boolean
      backgroundJobs: boolean
      exportTools: boolean
      aiIntegration: boolean
      monitoring: boolean
      testingSuite: boolean
      emailService: boolean
      analytics: boolean
    }
  - devQuickStart: {
      localUrl?: string
      containerUrl?: string
      envFiles?: string[]
      commands: {
        dev?: string
        build?: string
        lint?: string
        typecheck?: string
        test?: string
        testE2e?: string
      }
      endpoints: {
        health?: string
        metrics?: string
        chat?: string
        authSignin?: string
        authSignout?: string
      }
    }

- ContainerInfo:
  - id: string
  - name: string
  - image: string
  - networkMode: string
  - platform: string
  - status: string
  - uptime: string
  - restartPolicy: string
  - ports: string

- LogInfo:
  - filename: string
  - size: string
  - loadedAt: string
  - lines: string[]

Tasks:

1) At the top of src/app/page.tsx, define these interfaces/types.
2) Add a helper function getMockData(): { manifest: Manifest; container: ContainerInfo; log: LogInfo } that returns mock objects whose values match the current static content (v3 design).
3) Refactor the JSX:
   - Replace the static version label and timestamp with manifest.omniVersion and manifest.generatedAt.
   - Replace the “DEVELOPMENT” badge text with a label derived from manifest.profile.mode.
   - Dev Quick Start section:
     - URLs from manifest.devQuickStart.localUrl / containerUrl.
     - Environment list from manifest.devQuickStart.envFiles.
     - Commands from manifest.devQuickStart.commands.*.
     - Endpoint rows from manifest.devQuickStart.endpoints.*.
   - Profile & Stack:
     - Profile title/tagline/description from manifest.profile.
     - Each stack row from manifest.stack.* values.
   - Enabled Features:
     - Use manifest.features to decide if each feature row is rendered as enabled (checkmark/green) or disabled (muted/“X”).
   - Docker Container Information:
     - All fields from container.
   - Logfile Viewer:
     - filename/size/loadedAt from log.
     - Log body from log.lines (map over the array to render each line).

4) Keep the layout and Tailwind classes visually identical to the current design.
5) Do not introduce any file I/O or async functions yet. All data should still come from getMockData().

Output:
- The updated src/app/page.tsx with types + getMockData() + JSX using these fields.
```

Now you’ve got a manifest-aware UI that still runs purely off mocks.

---

## Step 3 – Swap mock data for real manifest/log reads

Final Codex prompt when you’re ready to wire it:

```text
Now replace the mock data with real reads from the filesystem.

Context:
- src/app/page.tsx currently uses getMockData() with hard-coded Manifest, ContainerInfo, and LogInfo objects.
- At runtime, OmniForge will generate:
  - omni.manifest.json in the project root
  - A log file (e.g. build-log.md or .log) under a known path (you can assume ./logs/bootstrap/build-log.md for now).
  - Container info will initially stay mocked or come from a static config; we’ll wire that later.

Goal:
- Implement server-side data loading for Manifest and LogInfo.
- Keep the component a server component.

Tasks:

1) Replace getMockData() with:
   - async function loadManifest(): Promise<Manifest | null>
   - async function loadLog(): Promise<LogInfo | null>
   that:
   - Uses Node fs/promises to:
     - Read process.cwd() + "/omni.manifest.json" and parse it to Manifest.
     - Read a build log file (e.g. "./logs/bootstrap/build-log.md") and split it into lines for LogInfo.lines.
   - Handles errors gracefully:
     - On any read/parse error, log to console.warn and return null.

2) Change HomePage to be an async server component:
   - export default async function HomePage() { ... }
   - Inside, call const manifest = await loadManifest(); const log = await loadLog(); const container = getMockContainerInfo();

3) Fallback behavior:
   - If manifest is null, render a minimal fallback:
     - A centered card saying “Your app is ready. OmniForge manifest not found yet.”
     - Do not render the full dashboard if manifest is missing.
   - If log is null, show a friendly message inside the Log Viewer area instead of sample lines.

4) Keep all existing JSX structure and Tailwind classes.
   - Only replace the mock data wiring; do not redesign the UI.

Output:
- The final src/app/page.tsx with loadManifest/loadLog implemented and used, plus a small getMockContainerInfo for now.
```

---

That’s the “best method” in practice:

* Use your `_build/omni-landing-design-v3.html` as visual ground truth.
* Do **two clean Codex passes**:

  * HTML → TSX (static)
  * Static TSX → typed + manifest-driven (mocked)
* Then a third, small pass to switch mocks to real manifest/log reads.

Keeps risk low, keeps the UI stable, and gives you natural checkpoints to inspect.
