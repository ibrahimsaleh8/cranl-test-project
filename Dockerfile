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

# Prisma + Next.js need DATABASE_URL at build time
# ARG DATABASE_URL=postgresql://neondb_owner:npg_Gr8RQCaBFNd4@ep-twilight-wildflower-agus16yi-pooler.c-2.eu-central-1.aws.neon.tech/qahwajige?sslmode=require&channel_binding=require
ARG DATABASE_URL=postgresql://postgresql:76lmSREChrCTn7MiCZf3Mw2AwzHDGVBL@new-db-ps2u8b:5432/new-db
ENV DATABASE_URL=$DATABASE_URL

# Generate Prisma Client
RUN npx prisma generate

# Build Next.js (standalone)
RUN npm run build

############################
# Runner (Production)
############################
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

# Security: run as non-root user
RUN addgroup --system --gid 1001 nodejs \
  && adduser --system --uid 1001 nextjs

# Copy standalone build output
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

USER nextjs

EXPOSE 3000

CMD ["node", "server.js"]
