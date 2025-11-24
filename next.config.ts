import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  // Enable React strict mode for development
  reactStrictMode: true,

  // Experimental features
  experimental: {
    // Enable typed routes
    typedRoutes: true,
  },

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
};

export default nextConfig;
