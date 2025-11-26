# =============================================================================
# Bloom - Production Dockerfile
# =============================================================================
# Multistage build for optimized production image
# Build: docker build -t bloom:latest .
# Run:   docker run -p 3000:3000 bloom:latest
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Dependencies
# -----------------------------------------------------------------------------
FROM node:22-alpine AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install pnpm
RUN corepack enable && corepack prepare pnpm@10.23.0 --activate

# Copy package files
COPY package.json pnpm-lock.yaml* ./

# Install dependencies (production only for smaller image)
RUN pnpm install --frozen-lockfile --prod=false

# -----------------------------------------------------------------------------
# Stage 2: Builder
# -----------------------------------------------------------------------------
FROM node:22-alpine AS builder
WORKDIR /app

RUN corepack enable && corepack prepare pnpm@10.23.0 --activate

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build arguments for environment
ARG NEXT_PUBLIC_APP_URL
ARG DATABASE_URL

# Disable telemetry during build
ENV NEXT_TELEMETRY_DISABLED=1

# Build the application
RUN pnpm build

# -----------------------------------------------------------------------------
# Stage 3: Runner (Production)
# -----------------------------------------------------------------------------
FROM node:22-alpine AS runner
WORKDIR /app

# Security: Run as non-root user
RUN addgroup --system --gid 1001 nodejs &&     adduser --system --uid 1001 nextjs

# Set production environment
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Copy only necessary files from builder
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Set ownership
RUN chown -R nextjs:nodejs /app

USER nextjs

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3     CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1

CMD ["node", "server.js"]
