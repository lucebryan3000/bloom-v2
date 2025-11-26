import fs from 'fs';
import path from 'path';
import React from 'react';

type ManifestEndpoint = { label?: string; path?: string };
type ManifestFeature = string | { key?: string; label?: string; enabled?: boolean };
type Manifest = {
  deployedBy?: string;
  omniVersion?: string;
  generatedAt?: string;
  deploymentTimeSeconds?: number;
  profile?: {
    key?: string;
    name?: string;
    tagline?: string;
    description?: string;
    mode?: string;
  };
  devQuickStart?: {
    localUrl?: string;
    containerUrl?: string;
    envFiles?: string[];
    commands?: string[];
    endpoints?: ManifestEndpoint[];
  };
  features?: ManifestFeature[];
  stack?: Record<string, string | string[]>;
  container?: {
    id?: string;
    name?: string;
    image?: string;
    network?: string;
    platform?: string;
    status?: string;
    uptime?: string;
    ports?: string[];
    restartPolicy?: string;
  };
};

type PackageInfo = { name?: string; version?: string };

function readJson<T>(filePath: string): T | null {
  try {
    const raw = fs.readFileSync(filePath, 'utf8');
    return JSON.parse(raw) as T;
  } catch (err) {
    console.warn(`[OmniForge] Unable to read ${filePath}:`, err);
    return null;
  }
}

function loadManifest(): Manifest | null {
  const manifestPath = path.join(process.cwd(), 'omni.manifest.json');
  return readJson<Manifest>(manifestPath);
}

function loadPackageInfo(): PackageInfo {
  const pkgPath = path.join(process.cwd(), 'package.json');
  return readJson<PackageInfo>(pkgPath) || {};
}

function formatDate(iso?: string) {
  if (!iso) return '';
  const dt = new Date(iso);
  if (Number.isNaN(dt.getTime())) return '';
  return dt.toLocaleString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  });
}

function normalizeFeatures(features?: ManifestFeature[]): string[] {
  if (!features) return [];
  return features
    .map((f) => {
      if (typeof f === 'string') return f;
      if (f?.enabled === false) return '';
      return f?.label || f?.key || '';
    })
    .filter(Boolean);
}

function normalizeCommands(manifest?: Manifest): string[] {
  if (manifest?.devQuickStart?.commands?.length) return manifest.devQuickStart.commands;
  return ['pnpm dev', 'pnpm build', 'pnpm lint', 'pnpm typecheck', 'pnpm test', 'pnpm test:e2e'];
}

function normalizeEndpoints(endpoints?: ManifestEndpoint[]): ManifestEndpoint[] {
  if (!endpoints || !endpoints.length) {
    return [
      { label: 'Health', path: '/api/monitoring/health' },
      { label: 'Metrics', path: '/api/monitoring/metrics' },
      { label: 'Chat', path: '/chat' },
      { label: 'Auth', path: '/signin · /signout' },
    ];
  }
  return endpoints;
}

function normalizeEnvFiles(envFiles?: string[]): string[] {
  if (envFiles?.length) return envFiles;
  return ['.env', '.env.local'];
}

function normalizePorts(ports?: string[]): string[] {
  if (ports?.length) return ports;
  return ['3000:3000'];
}

export default function HomePage() {
  const manifest = loadManifest();
  const pkg = loadPackageInfo();

  const omniVersion = manifest?.omniVersion || manifest?.deployedBy || 'OmniForge';
  const generatedAt = formatDate(manifest?.generatedAt);
  const profile = manifest?.profile;
  const profileName = profile?.name || profile?.key || 'Unknown profile';
  const profileTagline = profile?.tagline || 'Full-stack development environment';
  const profileMode = profile?.mode;
  const deployTime = manifest?.deploymentTimeSeconds
    ? `${manifest.deploymentTimeSeconds.toFixed(2)} minutes`
    : '';

  const localUrl = manifest?.devQuickStart?.localUrl || 'http://localhost:3000';
  const containerUrl = manifest?.devQuickStart?.containerUrl || 'http://<container-ip>:3000';
  const envFiles = normalizeEnvFiles(manifest?.devQuickStart?.envFiles);
  const commands = normalizeCommands(manifest);
  const endpoints = normalizeEndpoints(manifest?.devQuickStart?.endpoints);
  const features = normalizeFeatures(manifest?.features);
  const stack = manifest?.stack || {};
  const container = manifest?.container;

  const hasManifest = Boolean(manifest);
  const hasContainer = Boolean(container);

  return (
    <div className="w-full min-h-full bg-gradient-to-br from-slate-950 to-slate-900 p-8">
      <style>{`
        body {
          box-sizing: border-box;
        }
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(10px); }
          to { opacity: 1; transform: translateY(0); }
        }
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.7; }
        }
        @keyframes scaleIn {
          from { transform: scale(0.98); opacity: 0; }
          to { transform: scale(1); opacity: 1; }
        }
        .fade-in { animation: fadeIn 0.6s ease-out forwards; }
        .scale-in { animation: scaleIn 0.4s ease-out forwards; }
        .status-card { transition: all 0.3s ease; }
        .status-card:hover { transform: translateY(-2px); box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4); }
        .pulse-animation { animation: pulse 2s ease-in-out infinite; }
        .command-box { transition: all 0.2s ease; border-left: 2px solid rgb(30 58 138); }
        .command-box:hover { transform: translateY(-1px); background-color: rgb(51 65 85); }
        .log-console::-webkit-scrollbar { width: 8px; }
        .log-console::-webkit-scrollbar-track { background: rgb(51 65 85); border-radius: 4px; }
        .log-console::-webkit-scrollbar-thumb { background: rgb(71 85 105); border-radius: 4px; }
        .log-console::-webkit-scrollbar-thumb:hover { background: rgb(100 116 139); }
        .quick-start-glow { box-shadow: 0 8px 32px rgba(59, 130, 246, 0.15); }
      `}</style>

      <main className="max-w-7xl mx-auto space-y-8">
        <header className="text-center fade-in pb-6">
          <h1 className="text-5xl font-bold text-orange-500 mb-2">Deployed by OmniForge</h1>
          <p className="text-lg text-slate-400 font-medium">
            {omniVersion}
            {generatedAt ? ` · ${generatedAt}` : ''}
          </p>
          <p className="text-sm text-slate-500 italic mt-1">
            {profileTagline || 'Full-stack development environment'}
          </p>
          {!hasManifest && (
            <p className="text-xs text-slate-600 mt-2">
              Manifest not found; showing defaults. Run OmniForge to populate this page.
            </p>
          )}
        </header>

        <section className="bg-slate-900/80 rounded-2xl shadow-2xl p-8 fade-in border border-slate-800 quick-start-glow">
          <div className="flex items-center justify-between mb-8">
            <div>
              <h2 className="text-3xl font-semibold text-slate-100 flex items-center gap-3">
                <span className="text-3xl">🚀</span>
                <span>Dev Quick Start</span>
              </h2>
              {deployTime ? (
                <p className="text-sm text-slate-400 mt-2 ml-12">Deployment time: {deployTime}</p>
              ) : (
                <p className="text-sm text-slate-400 mt-2 ml-12">
                  {pkg?.name ? `${pkg.name}` : 'Next app'} {pkg?.version ? `v${pkg.version}` : ''}
                </p>
              )}
            </div>
            <span className="px-4 py-2 bg-green-900 text-green-300 rounded-lg text-sm font-semibold pulse-animation">
              {hasManifest ? '✓ Ready' : '⚠️ Manifest missing'}
            </span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="flex flex-col">
              <h3 className="text-xs font-bold text-slate-300 uppercase tracking-wider mb-4 flex items-center gap-2 pb-2 border-b border-slate-700">
                <span>🔗</span>
                <span>URLs</span>
              </h3>
              <div className="space-y-4 flex-grow">
                <div className="flex flex-col">
                  <span className="text-xs text-slate-500 uppercase mb-1">Local</span>
                  <a
                    href={localUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-blue-400 hover:text-blue-300 hover:underline font-mono text-sm transition-colors"
                  >
                    {localUrl}
                  </a>
                </div>
                <div className="flex flex-col">
                  <span className="text-xs text-slate-500 uppercase mb-1">Container</span>
                  <span className="text-blue-400 font-mono text-sm">{containerUrl}</span>
                </div>
                <div className="flex flex-col">
                  <span className="text-xs text-slate-500 uppercase mb-1">Environment</span>
                  <span className="text-slate-300 font-mono text-sm">
                    {envFiles.join(', ')}
                  </span>
                </div>
              </div>
              <div className="flex justify-center mt-8 pt-4 border-t border-slate-800">
                <a
                  href="#"
                  className="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-semibold transition-all hover:scale-105 active:scale-95 shadow-lg"
                >
                  Next Steps Checklist
                </a>
              </div>
            </div>

            <div>
              <h3 className="text-xs font-bold text-slate-300 uppercase tracking-wider mb-4 flex items-center gap-2 pb-2 border-b border-slate-700">
                <span>⌨️</span>
                <span>Commands</span>
              </h3>
              <div className="space-y-2">
                {commands.map((cmd) => (
                  <div
                    key={cmd}
                    className="command-box text-slate-200 font-mono text-sm bg-slate-800 px-3 py-2 rounded cursor-pointer"
                  >
                    {cmd}
                  </div>
                ))}
              </div>
            </div>

            <div>
              <h3 className="text-xs font-bold text-slate-300 uppercase tracking-wider mb-4 flex items-center gap-2 pb-2 border-b border-slate-700">
                <span>🌐</span>
                <span>Endpoints</span>
              </h3>
              <div className="space-y-3">
                {endpoints.map((ep, idx) => (
                  <div key={`${ep.label || ep.path}-${idx}`} className="flex flex-col">
                    <span className="text-xs text-blue-400 font-semibold mb-0.5">
                      {ep.label || 'Endpoint'}
                    </span>
                    <span className="text-slate-300 font-mono text-sm pl-1">
                      {ep.path || ''}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        {hasContainer && (
          <section className="scale-in" style={{ animationDelay: '0.2s', opacity: 0 }}>
            <div className="bg-slate-950/90 rounded-2xl shadow-xl p-8 border border-slate-800">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-2xl font-semibold text-white flex items-center gap-3">
                  <span className="text-2xl">🐳</span>
                  <span>Docker Container Information</span>
                </h2>
                <span className="px-4 py-2 bg-green-900 text-green-300 rounded-lg text-xs font-bold pulse-animation border border-green-800">
                  {container?.status || 'Connected'}
                </span>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                <div className="space-y-4">
                  <div className="flex items-start justify-between border-b border-slate-800 pb-3">
                    <span className="text-slate-500 text-xs uppercase tracking-wider font-semibold">Container ID</span>
                    <div className="text-slate-200 font-mono text-sm">{container?.id || '—'}</div>
                  </div>
                  <div className="flex items-start justify-between border-b border-slate-800 pb-3">
                    <span className="text-slate-500 text-xs uppercase tracking-wider font-semibold">Container Name</span>
                    <div className="text-slate-200 font-mono text-sm">{container?.name || '—'}</div>
                  </div>
                  <div className="flex items-start justify-between border-b border-slate-800 pb-3">
                    <span className="text-slate-500 text-xs uppercase tracking-wider font-semibold">Image</span>
                    <div className="text-slate-200 font-mono text-sm">{container?.image || '—'}</div>
                  </div>
                  <div className="flex items-start justify-between border-b border-slate-800 pb-3">
                    <span className="text-slate-500 text-xs uppercase tracking-wider font-semibold">Network</span>
                    <div className="text-slate-200 font-mono text-sm">{container?.network || '—'}</div>
                  </div>
                  <div className="flex items-start justify-between">
                    <span className="text-slate-500 text-xs uppercase tracking-wider font-semibold">Platform</span>
                    <div className="text-slate-200 font-mono text-sm">{container?.platform || '—'}</div>
                  </div>
                </div>

                <div className="space-y-4">
                  <div className="flex items-start justify-between border-b border-slate-800 pb-3">
                    <span className="text-slate-500 text-xs uppercase tracking-wider font-semibold">Status</span>
                    <div className="text-green-400 font-mono text-base font-semibold pulse-animation flex items-center gap-2">
                      <span className="text-xl">●</span> {container?.status || 'Running'}
                    </div>
                  </div>
                  <div className="flex items-start justify-between border-b border-slate-800 pb-3">
                    <span className="text-slate-500 text-xs uppercase tracking-wider font-semibold">Uptime</span>
                    <div className="text-slate-100 font-mono text-base font-medium">{container?.uptime || '—'}</div>
                  </div>
                  <div className="flex items-start justify-between border-b border-slate-800 pb-3">
                    <span className="text-slate-500 text-xs uppercase tracking-wider font-semibold">Ports</span>
                    <div className="text-slate-100 font-mono text-base font-medium">
                      {normalizePorts(container?.ports).map((p) => (
                        <div key={p}>{p}</div>
                      ))}
                    </div>
                  </div>
                  <div className="flex items-start justify-between">
                    <span className="text-slate-500 text-xs uppercase tracking-wider font-semibold">Restart Policy</span>
                    <div className="text-slate-200 font-mono text-sm">{container?.restartPolicy || '—'}</div>
                  </div>
                </div>
              </div>
            </div>
          </section>
        )}

        <section className="scale-in" style={{ animationDelay: '0.3s', opacity: 0 }}>
          <div className="status-card bg-slate-900/80 rounded-2xl shadow-xl p-6 border border-slate-800">
            <div className="flex items-start justify-between mb-8">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 bg-gradient-to-br from-green-600 to-green-700 rounded-xl flex items-center justify-center shadow-lg">
                  <span className="text-white font-bold text-xl">
                    {(profileName || 'D').slice(0, 1).toUpperCase()}
                  </span>
                </div>
                <div>
                  <h2 className="text-2xl font-semibold text-slate-100">{profileName}</h2>
                  <p className="text-sm text-slate-400 mt-1">
                    {profile?.description || profileTagline || 'Optimized for development workflow'}
                  </p>
                </div>
              </div>
              <span className="px-4 py-2 bg-green-900 text-green-300 rounded-lg text-xs font-bold pulse-animation border border-green-800">
                {profileMode ? `${profileMode} mode` : 'Active'}
              </span>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-x-12 gap-y-0 mb-8">
              <div className="space-y-0">
                <div className="flex items-start justify-between py-3 border-b border-slate-800">
                  <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">Runtime</span>
                  <div className="text-right">
                    <div className="text-sm text-slate-200 font-mono">
                      {stack.runtime ||
                        'Next.js · Node · pnpm'}
                    </div>
                  </div>
                </div>
                <div className="flex items-start justify-between py-3 border-b border-slate-800">
                  <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">Database</span>
                  <div className="text-right">
                    <div className="text-sm text-slate-200 font-mono">{stack.database || '—'}</div>
                  </div>
                </div>
                <div className="flex items-start justify-between py-3 border-b border-slate-800">
                  <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">Auth</span>
                  <div className="text-right">
                    <div className="text-sm text-slate-200 font-mono">{stack.auth || '—'}</div>
                  </div>
                </div>
                <div className="flex items-start justify-between py-3 border-b border-slate-800">
                  <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">AI</span>
                  <div className="text-right">
                    <div className="text-sm text-slate-200 font-mono">
                      {Array.isArray(stack.ai) ? stack.ai.join(' · ') : stack.ai || '—'}
                    </div>
                  </div>
                </div>
                <div className="flex items-start justify-between py-3">
                  <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">Jobs</span>
                  <div className="text-right">
                    <div className="text-sm text-slate-200 font-mono">{stack.jobs || '—'}</div>
                  </div>
                </div>
              </div>

              <div className="space-y-0">
                <div className="flex items-start justify-between py-3 border-b border-slate-800">
                  <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">Logging</span>
                  <div className="text-right">
                    <div className="text-sm text-slate-200 font-mono">{stack.logging || '—'}</div>
                  </div>
                </div>
                <div className="flex items-start justify-between py-3 border-b border-slate-800">
                  <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">UI</span>
                  <div className="text-right">
                    <div className="text-sm text-slate-200 font-mono">
                      {Array.isArray(stack.ui) ? stack.ui.join(' · ') : stack.ui || '—'}
                    </div>
                  </div>
                </div>
                <div className="flex items-start justify-between py-3 border-b border-slate-800">
                  <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">State</span>
                  <div className="text-right">
                    <div className="text-sm text-slate-200 font-mono">{stack.state || '—'}</div>
                  </div>
                </div>
                <div className="flex items-start justify-between py-3 border-b border-slate-800">
                  <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">Exports</span>
                  <div className="text-right">
                    <div className="text-sm text-slate-200 font-mono">
                      {Array.isArray(stack.exports) ? stack.exports.join(' · ') : stack.exports || '—'}
                    </div>
                  </div>
                </div>
                <div className="flex items-start justify-between py-3 border-b border-slate-800">
                  <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">Testing</span>
                  <div className="text-right">
                    <div className="text-sm text-slate-200 font-mono">
                      {Array.isArray(stack.testing) ? stack.testing.join(' · ') : stack.testing || '—'}
                    </div>
                  </div>
                </div>
                <div className="flex items-start justify-between py-3">
                  <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">Quality</span>
                  <div className="text-right">
                    <div className="text-sm text-slate-200 font-mono">
                      {Array.isArray(stack.quality) ? stack.quality.join(' · ') : stack.quality || '—'}
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="pt-6 border-t border-slate-800">
              <h3 className="text-lg font-semibold text-slate-100 mb-4 flex items-center gap-2">
                <span>⚡</span>
                <span>Enabled Features</span>
              </h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
                {features.length ? (
                  features.map((feat) => (
                    <div key={feat}>
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-green-400 text-base font-bold">✓</span>
                        <span className="text-sm font-semibold text-slate-100">{feat}</span>
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="opacity-80">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="text-slate-400 text-base font-bold">—</span>
                      <span className="text-sm font-semibold text-slate-200">No features reported</span>
                    </div>
                    <div className="text-xs text-slate-500 pl-6">Run OmniForge to populate manifest features.</div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </section>

        <section className="scale-in" style={{ animationDelay: '0.4s', opacity: 0 }}>
          <div className="bg-slate-900/80 rounded-2xl shadow-xl p-8 border border-slate-800">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-semibold text-slate-100 flex items-center gap-3">
                <span className="text-2xl">📊</span>
                <span>Logfile Viewer</span>
              </h2>
              <button className="px-5 py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-100 rounded-lg text-sm font-semibold transition-all hover:scale-105 active:scale-95 flex items-center gap-2 border border-slate-700">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"></path>
                </svg>
                Download Log
              </button>
            </div>

            <div className="log-console bg-slate-950 rounded-xl p-6 font-mono text-sm text-slate-200 max-h-96 overflow-y-auto border border-slate-800 shadow-inner">
              <div className="space-y-1">
                <div className="text-slate-400">
                  <span className="text-slate-500">—</span>{' '}
                  <span className="text-blue-400 font-semibold">[INFO]</span>{' '}
                  <span className="text-slate-300">
                    {hasManifest
                      ? `Profile ${profileName} loaded${profileMode ? ` (${profileMode})` : ''}`
                      : 'Run OmniForge to populate manifest data.'}
                  </span>
                </div>
                <div className="text-slate-400">
                  <span className="text-slate-500">—</span>{' '}
                  <span className="text-blue-400 font-semibold">[INFO]</span>{' '}
                  <span className="text-slate-300">Next steps: {commands.slice(0, 2).join(' · ')}</span>
                </div>
              </div>
            </div>

            <div className="mt-6 pt-4 border-t border-slate-800">
              <div className="flex items-center justify-between text-sm">
                <div className="flex items-center gap-4 text-slate-400">
                  <span className="flex items-center gap-2">
                    <span className="text-slate-500">📄</span>
                    <span className="font-mono text-slate-300">omni.manifest.json</span>
                  </span>
                  <span className="text-slate-600">·</span>
                  <span className="font-mono">{hasManifest ? 'Loaded' : 'Not found'}</span>
                </div>
                <span className="text-slate-400">
                  {hasManifest ? 'Using manifest data' : 'Fallback view'}
                </span>
              </div>
            </div>
          </div>
        </section>
      </main>
    </div>
  );
}
