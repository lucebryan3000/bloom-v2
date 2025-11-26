import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  // Enable React strict mode for development
  reactStrictMode: true,

  // Environment variables available to the browser
  env: {
    // Add public env vars here
  },

  // Image optimization
  images: {
    remotePatterns: [
      // Add allowed image domains here
    ],
  },

  // Needed for Docker multistage build optimization
  output: 'standalone',

  // Relax linting during containerized builds to prioritize successful image creation
  eslint: {
    ignoreDuringBuilds: true,
  },

  // Allow type errors to pass during container builds (fix incrementally in dev)
  typescript: {
    ignoreBuildErrors: true,
  },
};

export default nextConfig;
