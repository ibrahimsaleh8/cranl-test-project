# syntax=docker.io/docker/dockerfile:1

############################
# Base
############################
FROM node:20-alpine AS base
RUN apk add --no-cache libc6-compat
WORKDIR /app

############################
# Dependencies
############################
FROM base AS deps
COPY package.json package-lock.json ./
RUN npm ci

############################
# Builder
############################
FROM base AS builder
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Prisma client generation
RUN npx prisma generate

# Build Next.js (DATABASE_URL must exist at build time for Prisma)
ARG DATABASE_URL
ENV DATABASE_URL=$DATABASE_URL

RUN npm run build

############################
# Runner (Production)
############################
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

# Security: non-root user
RUN addgroup --system --gid 1001 nodejs \
  && adduser --system --uid 1001 nextjs

# Copy standalone output
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

USER nextjs

EXPOSE 3000

CMD ["node", "server.js"]
